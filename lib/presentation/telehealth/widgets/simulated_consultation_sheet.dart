import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../data/models/telehealth_appointment_model.dart';
import '../../vitals/vitals_notifier.dart';
import '../telehealth_notifier.dart';

class SimulatedConsultationSheet extends ConsumerStatefulWidget {
  final TelehealthAppointmentModel appointment;

  const SimulatedConsultationSheet({super.key, required this.appointment});

  @override
  ConsumerState<SimulatedConsultationSheet> createState() =>
      _SimulatedConsultationSheetState();
}

class _SimulatedConsultationSheetState
    extends ConsumerState<SimulatedConsultationSheet> {
  int _secondsElapsed = 0;
  Timer? _callTimer;

  @override
  void initState() {
    super.initState();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  String _formatCallDuration(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final telehealthState = ref.watch(telehealthNotifierProvider);
    final telehealthNotifier = ref.read(telehealthNotifierProvider.notifier);
    final vitalsState = ref.watch(vitalsNotifierProvider);

    final currentTelemetry = vitalsState.currentTelemetry;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Simulated Doctor Remote Video Feed
            Positioned.fill(
              child: Container(
                color: const Color(0xFF111721),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: Icon(
                            Icons.person_rounded,
                            size: 80,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.appointment.doctorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.appointment.specialty} • Encrypted Telehealth Session',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatCallDuration(_secondsElapsed),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Live Clinical Vitals Overlay Banner (Doctor Telemetry HUD)
            if (telehealthState.isSharingVitals)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(200),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.secondary.withAlpha(120),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildOverlayVital(
                        'BP',
                        '${currentTelemetry?.systolic ?? 120}/${currentTelemetry?.diastolic ?? 80}',
                        'mmHg',
                        colorScheme.secondary,
                      ),
                      _buildOverlayVital(
                        'HR',
                        '${currentTelemetry?.pulseRate ?? 72}',
                        'bpm',
                        colorScheme.primary,
                      ),
                      _buildOverlayVital(
                        'GLUC',
                        '${currentTelemetry?.glucoseMgDl ?? 108}',
                        'mg/dL',
                        Colors.amber,
                      ),
                      _buildOverlayVital(
                        'SpO2',
                        '${currentTelemetry?.oxygenSaturation ?? 98}%',
                        'O2',
                        colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ),

            // Self-view PiP (Picture in Picture)
            Positioned(
              top: telehealthState.isSharingVitals ? 84 : 20,
              right: 16,
              child: Container(
                width: 90,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Center(
                  child: telehealthState.isCameraOff
                      ? const Icon(
                          Icons.videocam_off_rounded,
                          color: Colors.white54,
                        )
                      : const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white70,
                        ),
                ),
              ),
            ),

            // Bottom Clinical HUD Controls
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(220),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: telehealthState.isMicMuted
                            ? Colors.red.withAlpha(50)
                            : Colors.white12,
                      ),
                      icon: Icon(
                        telehealthState.isMicMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        color: telehealthState.isMicMuted
                            ? Colors.red
                            : Colors.white,
                      ),
                      onPressed: () => telehealthNotifier.toggleMic(),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: telehealthState.isCameraOff
                            ? Colors.red.withAlpha(50)
                            : Colors.white12,
                      ),
                      icon: Icon(
                        telehealthState.isCameraOff
                            ? Icons.videocam_off_rounded
                            : Icons.videocam_rounded,
                        color: telehealthState.isCameraOff
                            ? Colors.red
                            : Colors.white,
                      ),
                      onPressed: () => telehealthNotifier.toggleCamera(),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: telehealthState.isSharingVitals
                            ? colorScheme.secondary.withAlpha(60)
                            : Colors.white12,
                      ),
                      icon: Icon(
                        Icons.monitor_heart_rounded,
                        color: telehealthState.isSharingVitals
                            ? colorScheme.secondary
                            : Colors.white54,
                      ),
                      onPressed: () => telehealthNotifier.toggleVitalSharing(),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(backgroundColor: Colors.red),
                      icon: const Icon(
                        Icons.call_end_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        telehealthNotifier.endConsultationCall();
                        Navigator.of(context).pop();
                        AppFeedback.showSuccess(
                          context,
                          'Telehealth consultation completed. Clinical summary saved.',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayVital(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white.withAlpha(180),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(fontSize: 8, color: Colors.white.withAlpha(140)),
            ),
          ],
        ),
      ],
    );
  }
}
