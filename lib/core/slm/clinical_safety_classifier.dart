enum ClinicalSafetyTier {
  benign,
  acuteEmergency,
  selfHarmCrisis,
  unauthorizedDosageAlteration,
  unverifiedPharmaceutical,
}

class ClinicalSafetyResult {
  final ClinicalSafetyTier tier;
  final bool isGated;
  final String? flaggedCategory;
  final String? escalationProtocol;
  final String? gatingMessage;

  const ClinicalSafetyResult({
    required this.tier,
    required this.isGated,
    this.flaggedCategory,
    this.escalationProtocol,
    this.gatingMessage,
  });

  bool get isSafe => !isGated;
}

class ClinicalSafetyClassifier {
  // Acute Emergency Red Flags
  static const List<String> _acuteEmergencyKeywords = [
    'crushing chest pain',
    'chest pain radiating',
    'sudden left arm numbness',
    'facial drooping',
    'slurred speech',
    'cant breathe',
    'cannot breathe',
    'choking',
    'anaphylaxis',
    'massive hemorrhage',
    'unconscious',
    'seizure lasting',
    'coughing blood',
  ];

  // Self-Harm / Crisis Screening
  static const List<String> _selfHarmKeywords = [
    'suicide',
    'kill myself',
    'end my life',
    'overdose on purpose',
    'want to die',
    'hurt myself',
    'cutting myself',
  ];

  // Unauthorized Prescription Alterations
  static const List<String> _dosageAlterationKeywords = [
    'double my dose',
    'triple my dose',
    'stop taking my insulin',
    'quit my blood pressure meds',
    'change my dosage without doctor',
    'take extra pills',
  ];

  ClinicalSafetyResult evaluateInput(String prompt) {
    final lower = prompt.toLowerCase();

    // 1. Acute Emergency Screening
    for (final phrase in _acuteEmergencyKeywords) {
      if (lower.contains(phrase)) {
        return const ClinicalSafetyResult(
          tier: ClinicalSafetyTier.acuteEmergency,
          isGated: true,
          flaggedCategory: 'Acute Life-Threatening Emergency',
          escalationProtocol: 'EMERGENCY_SERVICES_DISPATCH_911',
          gatingMessage: 'Immediate Medical Escalation Required: The symptoms reported describe a potential medical emergency (cardiovascular or acute respiratory event). Please contact 911 / 112 or proceed immediately to the nearest Emergency Department.',
        );
      }
    }

    // 2. Self-Harm Screening
    for (final phrase in _selfHarmKeywords) {
      if (lower.contains(phrase)) {
        return const ClinicalSafetyResult(
          tier: ClinicalSafetyTier.selfHarmCrisis,
          isGated: true,
          flaggedCategory: 'Psychiatric Crisis / Suicide Prevention',
          escalationProtocol: 'CRISIS_LIFELINE_988',
          gatingMessage: 'Support Available 24/7: If you or someone you know is in crisis, please dial or text 988 for the Suicide & Crisis Lifeline, or visit your nearest emergency health center immediately.',
        );
      }
    }

    // 3. Unauthorized Medication Dosage Modifications
    for (final phrase in _dosageAlterationKeywords) {
      if (lower.contains(phrase)) {
        return const ClinicalSafetyResult(
          tier: ClinicalSafetyTier.unauthorizedDosageAlteration,
          isGated: true,
          flaggedCategory: 'Pharmacotherapy Safety Guardrail',
          escalationProtocol: 'PREVENT_UNSUPERVISED_DOSAGE_TITRATION',
          gatingMessage: 'Clinical Safety Warning: Modifying prescription dosage or discontinuing essential maintenance medications without attending physician supervision carries severe pharmacological risk. Please consult your prescribing specialist prior to any regimen changes.',
        );
      }
    }

    return const ClinicalSafetyResult(
      tier: ClinicalSafetyTier.benign,
      isGated: false,
    );
  }
}
