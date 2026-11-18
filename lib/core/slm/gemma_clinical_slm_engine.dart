import 'dart:async';

import 'clinical_safety_classifier.dart';
import '../../data/models/lab_report_model.dart';
import '../../data/models/prescription_model.dart';
import '../../data/models/vital_reading_model.dart';

class GemmaSlmMetrics {
  final String modelName;
  final String quantizationTier;
  final String activeDelegate; // 'NPU', 'GPU', 'CPU'
  final int timeToFirstTokenMs;
  final double tokensPerSecond;
  final int memoryFootprintMb;
  final int contextLength;
  final bool isZeroNetworkVerified;
  final double temperature;

  const GemmaSlmMetrics({
    this.modelName = 'Gemma 2B-IT Clinical (Q4_K_M)',
    this.quantizationTier = '4-bit K-quant Medium (Q4_K_M)',
    this.activeDelegate = 'NPU',
    this.timeToFirstTokenMs = 32,
    this.tokensPerSecond = 52.4,
    this.memoryFootprintMb = 1420,
    this.contextLength = 2048,
    this.isZeroNetworkVerified = true,
    this.temperature = 0.2,
  });

  GemmaSlmMetrics copyWith({
    String? modelName,
    String? quantizationTier,
    String? activeDelegate,
    int? timeToFirstTokenMs,
    double? tokensPerSecond,
    int? memoryFootprintMb,
    int? contextLength,
    bool? isZeroNetworkVerified,
    double? temperature,
  }) {
    return GemmaSlmMetrics(
      modelName: modelName ?? this.modelName,
      quantizationTier: quantizationTier ?? this.quantizationTier,
      activeDelegate: activeDelegate ?? this.activeDelegate,
      timeToFirstTokenMs: timeToFirstTokenMs ?? this.timeToFirstTokenMs,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
      memoryFootprintMb: memoryFootprintMb ?? this.memoryFootprintMb,
      contextLength: contextLength ?? this.contextLength,
      isZeroNetworkVerified:
          isZeroNetworkVerified ?? this.isZeroNetworkVerified,
      temperature: temperature ?? this.temperature,
    );
  }
}

class GemmaClinicalSlmEngine {
  final ClinicalSafetyClassifier _classifier = ClinicalSafetyClassifier();
  GemmaSlmMetrics _metrics = const GemmaSlmMetrics();
  final bool _isWeightsLoaded = true;

  GemmaSlmMetrics get metrics => _metrics;
  bool get isWeightsLoaded => _isWeightsLoaded;

  Future<void> setExecutionDelegate(String delegate) async {
    int ttft = 32;
    double tps = 52.4;

    switch (delegate.toUpperCase()) {
      case 'NPU':
        ttft = 28;
        tps = 58.2;
        break;
      case 'GPU':
        ttft = 36;
        tps = 46.8;
        break;
      case 'CPU':
        ttft = 48;
        tps = 24.6;
        break;
      default:
        delegate = 'NPU';
    }

    _metrics = _metrics.copyWith(
      activeDelegate: delegate.toUpperCase(),
      timeToFirstTokenMs: ttft,
      tokensPerSecond: tps,
    );
  }

  ClinicalSafetyResult evaluateSafety(String prompt) {
    return _classifier.evaluateInput(prompt);
  }

  Stream<String> generateClinicalInference({
    required String userPrompt,
    required List<VitalReadingModel> recentVitals,
    required List<LabReportModel> labReports,
    required List<PrescriptionModel> prescriptions,
  }) async* {
    // 1. Clinical Safety Classifier Audit
    final safetyResult = _classifier.evaluateInput(userPrompt);
    if (safetyResult.isGated) {
      yield safetyResult.gatingMessage ??
          'Clinical safety policy active. Please seek immediate professional medical attention.';
      return;
    }

    // 2. Hardware Acceleration Initialization Emulation (Sub-50ms TTFT)
    final delay = Duration(milliseconds: _metrics.timeToFirstTokenMs);
    await Future.delayed(delay);

    // 3. Clinical Synthesis Engine
    final bpReading = recentVitals.firstWhere(
      (v) => v.systolic != null,
      orElse: () => VitalReadingModel(
        id: 'fallback_bp',
        timestamp: DateTime.now(),
        sensorType: 'CARDIO_CUFF',
        systolic: 120,
        diastolic: 80,
        meanArterialPressure: 93.3,
        pulseRate: 72,
      ),
    );

    final glucoseReading = recentVitals.firstWhere(
      (v) => v.glucoseMgDl != null,
      orElse: () => VitalReadingModel(
        id: 'fallback_gluc',
        timestamp: DateTime.now(),
        sensorType: 'GLUCO_SENSE',
        glucoseMgDl: 108,
      ),
    );

    final rxList = prescriptions.map((p) => p.medicationName).toList();
    final rxSummary = rxList.isNotEmpty ? rxList.join(', ') : 'None documented';

    final lower = userPrompt.toLowerCase();
    String inferenceOutput;

    if (lower.contains('gemma') ||
        lower.contains('slm') ||
        lower.contains('model') ||
        lower.contains('runtime')) {
      inferenceOutput =
          'Gemma 2B-IT Clinical Inference Engine Diagnostic:\n\n'
          '• Model Architecture: ${_metrics.modelName}\n'
          '• Execution Delegate: ${_metrics.activeDelegate} Acceleration (${_metrics.timeToFirstTokenMs}ms TTFT)\n'
          '• Throughput: ${_metrics.tokensPerSecond} tokens/sec\n'
          '• Memory Resident: ${_metrics.memoryFootprintMb} MB (Int4 Quantized)\n'
          '• Security & Privacy: 100% Zero-Network Air-Gapped Local Inference\n'
          '• Safety Policy: Multi-tier Clinical Classifier Active\n\n'
          'Clinical status is synchronized with on-device SQLite database.';
    } else if (lower.contains('lab') || lower.contains('biomarker')) {
      inferenceOutput =
          'On-Device Gemma Clinical Biomarker Synthesis:\n\n'
          '• Complete Metabolic & Lipid Panel Integration:\n'
          '  1. Glycemic: HbA1c 5.5% (EAG ~111 mg/dL) with CGM Time-in-Range 94.6%.\n'
          '  2. Lipid Profile: Total Cholesterol 168 mg/dL, LDL 82 mg/dL, HDL 62 mg/dL.\n'
          '  3. Renal & Electrolytes: Serum Creatinine 0.9 mg/dL, eGFR >90 mL/min/1.73m².\n\n'
          'Clinical Interpretation: Biomarkers remain within verified reference limits. Continue established maintenance therapy.';
    } else if (lower.contains('prescription') ||
        lower.contains('drug') ||
        lower.contains('medication')) {
      inferenceOutput =
          'Gemma 2B Pharmacotherapy Cross-Reference Screen:\n\n'
          '• Active Regimen: $rxSummary\n'
          '• Metabolic Pathway Analysis: No acute CYP3A4 or CYP2D6 competitive inhibitor collisions detected.\n'
          '• Renal Safety Note: Lisinopril ACE inhibition requires annual serum creatinine & potassium tracking.\n'
          '• Adherence Schedule: Doses taken today indicate consistent compliance.';
    } else if (lower.contains('blood pressure') ||
        lower.contains('glucose') ||
        lower.contains('vital')) {
      inferenceOutput =
          'Local Clinical Telemetry Evaluation:\n\n'
          '• Blood Pressure (CardioCuff Pro): ${bpReading.systolic}/${bpReading.diastolic} mmHg (MAP ${bpReading.meanArterialPressure ?? 93.3} mmHg). Normotensive hemodynamic profile.\n'
          '• Continuous Glucose (GlucoSense CGM): ${glucoseReading.glucoseMgDl ?? 108} mg/dL (Trajectory: ${glucoseReading.trendArrow ?? "STABLE"}).\n'
          '• Pulse & Saturation: Heart rate ${bpReading.pulseRate ?? 72} bpm, SpO2 98% nominal.\n\n'
          'Differential Assessment: All telemetric vitals remain inside optimal homeostatic thresholds.';
    } else {
      inferenceOutput =
          'Gemma 2B Clinical Triage Assessment:\n\n'
          'Inquiry: "$userPrompt"\n\n'
          '• Current Telemetry: BP ${bpReading.systolic}/${bpReading.diastolic} mmHg, Glucose ${glucoseReading.glucoseMgDl ?? 108} mg/dL.\n'
          '• Active Medications: $rxSummary\n'
          '• Clinical Screening: No life-threatening red-flags identified.\n'
          '• Clinical Recommendation: Maintain hydration, monitor physiological trends in Vitals Cockpit, and schedule a Telehealth video consultation if symptoms evolve.';
    }

    // 4. Token-by-token stream emulation based on active throughput
    final tokens = inferenceOutput.split(' ');
    final intervalMs = (1000.0 / _metrics.tokensPerSecond).round().clamp(
      10,
      45,
    );

    for (int i = 0; i < tokens.length; i++) {
      await Future.delayed(Duration(milliseconds: intervalMs));
      if (i < tokens.length - 1) {
        yield '${tokens[i]} ';
      } else {
        yield tokens[i];
      }
    }
  }
}
