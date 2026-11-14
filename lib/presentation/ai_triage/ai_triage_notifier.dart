import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/injection_container.dart';
import '../../data/models/ai_triage_model.dart';
import '../../domain/repositories/ai_triage_repository.dart';
import '../../domain/repositories/lab_repository.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../../domain/repositories/vitals_repository.dart';

class AiTriageState {
  final bool isLoading;
  final bool isCorrelating;
  final bool isStreaming;
  final List<AiTriageMessageModel> messages;
  final String? errorMessage;

  const AiTriageState({
    this.isLoading = false,
    this.isCorrelating = false,
    this.isStreaming = false,
    this.messages = const [],
    this.errorMessage,
  });

  AiTriageState copyWith({
    bool? isLoading,
    bool? isCorrelating,
    bool? isStreaming,
    List<AiTriageMessageModel>? messages,
    String? errorMessage,
  }) {
    return AiTriageState(
      isLoading: isLoading ?? this.isLoading,
      isCorrelating: isCorrelating ?? this.isCorrelating,
      isStreaming: isStreaming ?? this.isStreaming,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
    );
  }
}

class AiTriageNotifier extends Notifier<AiTriageState> {
  late final AiTriageRepository _triageRepo;
  late final VitalsRepository _vitalsRepo;
  late final LabRepository _labRepo;
  late final PrescriptionRepository _rxRepo;

  @override
  AiTriageState build() {
    _triageRepo = sl<AiTriageRepository>();
    _vitalsRepo = sl<VitalsRepository>();
    _labRepo = sl<LabRepository>();
    _rxRepo = sl<PrescriptionRepository>();
    Future.microtask(_loadHistory);
    return const AiTriageState(isLoading: true);
  }

  Future<void> _loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final history = await _triageRepo.getChatHistory();
      state = state.copyWith(isLoading: false, messages: history);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> sendPrompt(String text) async {
    if (text.trim().isEmpty || state.isStreaming) return;

    const uuid = Uuid();
    final userMsg = AiTriageMessageModel(
      id: 'msg_${uuid.v4().substring(0, 8)}',
      sender: 'USER',
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    // Append user message immediately
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isCorrelating: true,
      isStreaming: true,
    );

    await _triageRepo.saveMessage(userMsg);

    final aiMsgId = 'msg_${uuid.v4().substring(0, 8)}';
    AiTriageMessageModel streamingAiMsg = AiTriageMessageModel(
      id: aiMsgId,
      sender: 'AI',
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    try {
      // 1. Fetch live clinical context from repositories
      final vitals = await _vitalsRepo.getHistoricalVitals(limit: 14);
      final labs = await _labRepo.getLabReports();
      final rx = await _rxRepo.getPrescriptions();

      // Brief correlation indicator
      await Future.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(
        isCorrelating: false,
        messages: [...state.messages, streamingAiMsg],
      );

      final tokenStream = _triageRepo.generateClinicalTriageResponse(
        userPrompt: text,
        recentVitals: vitals,
        labReports: labs,
        prescriptions: rx,
      );

      final buffer = StringBuffer();
      await for (final token in tokenStream) {
        buffer.write(token);
        streamingAiMsg = streamingAiMsg.copyWith(content: buffer.toString());

        // Update last message immutably
        final currentMessages = List<AiTriageMessageModel>.from(state.messages);
        if (currentMessages.isNotEmpty && currentMessages.last.id == aiMsgId) {
          currentMessages[currentMessages.length - 1] = streamingAiMsg;
          state = state.copyWith(messages: currentMessages);
        }
      }

      // Finalize and save
      final finalizedMsg = streamingAiMsg.copyWith(
        isStreaming: false,
        clinicalSummary: 'Triage assessment complete',
      );
      await _triageRepo.saveMessage(finalizedMsg);

      final currentMessages = List<AiTriageMessageModel>.from(state.messages);
      if (currentMessages.isNotEmpty && currentMessages.last.id == aiMsgId) {
        currentMessages[currentMessages.length - 1] = finalizedMsg;
        state = state.copyWith(messages: currentMessages);
      }
    } catch (e) {
      final errorMsg = streamingAiMsg.copyWith(
        content:
            'Clinical triage service encountered a transient correlation issue: $e',
        isStreaming: false,
      );
      final currentMessages = List<AiTriageMessageModel>.from(state.messages);
      if (currentMessages.isNotEmpty && currentMessages.last.id == aiMsgId) {
        currentMessages[currentMessages.length - 1] = errorMsg;
      } else {
        currentMessages.add(errorMsg);
      }
      state = state.copyWith(messages: currentMessages);
    } finally {
      // Strictly guaranteed stream cleanup
      state = state.copyWith(isStreaming: false, isCorrelating: false);
    }
  }

  Future<void> clearHistory() async {
    await _triageRepo.clearHistory();
    state = state.copyWith(messages: const []);
  }
}

final aiTriageNotifierProvider =
    NotifierProvider<AiTriageNotifier, AiTriageState>(() {
      return AiTriageNotifier();
    });
