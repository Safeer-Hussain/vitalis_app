# Vitalis Product Requirements Document (PRD)

## Clinical Telemetry, Telehealth, Lab Diagnostics & AI Triage Ecosystem
- Product Name: Vitalis Clinical Ecosystem
- Version: 1.0.0-PROD
- Classification: Software as a Medical Device (SaMD) Support & Clinical Information System
- Engineering Standard: Clean Architecture, Offline-First, Zero Hardcoded Styles, Strict Zero-Emoji Code Standard

---

## 1. Executive Summary & Vision
Vitalis is an enterprise-grade digital health ecosystem bridging native biometric hardware telemetry, secure encrypted local clinical vaults, board-certified telemedicine scheduling, longitudinal laboratory analyte trend tracking, and on-device natural language clinical triage. Designed for rapid clinical decision support and patient empowerment, Vitalis adheres strictly to clean-room engineering standards, ensuring deterministic reliability across mobile, tablet, and foldable form factors.

---

## 2. Clinical System Architecture
Vitalis enforces a strict Feature-First Clean Architecture + MVVM separation of concerns:

```
+-------------------------------------------------------------+
|                     Presentation Layer                      |
| (Riverpod Notifiers, AdaptiveScaffold, Responsive Panes)    |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                        Domain Layer                         |
|    (Entities, Clinical Repositories Interfaces, Use Cases)   |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                         Data Layer                          |
|  (Data Sources, DTO Models, SQLite DAO, Platform Channels)  |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                  Core Infrastructure & Native               |
| (Encrypted SQLite DB, Dio Mock Network, Method/EventBridge) |
+-------------------------------------------------------------+
```

### Architectural Principles:
1. Unidirectional Data Flow: Riverpod `NotifierProvider` and `AsyncNotifierProvider` emit immutable state structures.
2. Dependency Inversion: Presentation interacts strictly through repository interfaces registered via `get_it`.
3. Persistent Offline Vault: SQLite tables (`vitals`, `doctors`, `appointments`, `lab_reports`, `biomarkers`, `prescriptions`, `ai_chat_history`) ensure 100% functionality without active WAN connectivity.

---

## 3. Native Medical Sensor Bridge Specification
The ecosystem communicates with medical sensors via asynchronous platform channels:
- Method Channel: `com.safeer.vitalis/medical_devices`
  - Methods: `scanClinicalSensors`, `pairMedicalDevice`, `disconnectDevice`, `triggerCalibration`
- Event Channel: `com.safeer.vitalis/clinical_telemetry`
  - Interval: 2000ms continuous streaming
  - CRC32 Checksum Validation: Packets failing CRC32 validation are rejected prior to UI ingestion.

### Supported Sensor Hardware Profiles:
1. CardioCuff Pro (BLE Hemodynamic BP Monitor):
   - Systolic Pressure: 90 - 180 mmHg
   - Diastolic Pressure: 60 - 120 mmHg
   - Mean Arterial Pressure (MAP): Computed as `(2 * Diastolic + Systolic) / 3`
   - Pulse Rate: 45 - 160 bpm
   - Arrhythmia Detection: Binary boolean flag (`irregularHeartbeat`)
2. GlucoSense CGM (Continuous Glucose Monitor):
   - Interstitial Glucose: 70 - 240 mg/dL (with dynamic mmol/L conversion: `value / 18.0182`)
   - Glycemic Trend: `RISING_FAST`, `RISING`, `STABLE`, `FALLING`, `FALLING_FAST`
   - Time-in-Range (TIR): Target 70-180 mg/dL adherence percentage
3. OxyPulse Clinical (Pulse Oximeter & Core Thermometry):
   - Oxygen Saturation (SpO2): 92 - 100%
   - Perfusion Index (PI): 0.5 - 12.0%
   - Core Temperature: 36.1 - 38.5 deg C (with Fahrenheit toggle: `(temp * 9/5) + 32`)

---

## 4. Telemedicine & Consultation Protocols
- Scheduling Model: Real-time conflict-free slot booking across 21 board-certified specialists.
- Consultation Modes:
  - High-Definition Video Telehealth (Simulated WebRTC bidirectional room with mute, camera toggle, and clinical note stream).
  - Outpatient In-Clinic Consultation.
- Status Lifecycle: `CONFIRMED` -> `IN_PROGRESS` -> `COMPLETED` or `CANCELLED`.
- Data Protection: Doctor credentials, NPI numbers, and licensing verification states stored immutably.

---

## 5. Biomarker Diagnostics & Reference Range Matrices
Laboratory diagnostics vault supports multi-panel clinical diagnostics:

| Panel Code | Panel Name | Analyte Name | Standard Reference Range | Clinical Unit |
| :--- | :--- | :--- | :--- | :--- |
| CBC-DIFF-W8 | Complete Blood Count | White Blood Cells (WBC) | 4.5 - 11.0 | x10^3/uL |
| CBC-DIFF-W8 | Complete Blood Count | Hemoglobin (Hgb) | 13.8 - 17.2 | g/dL |
| CBC-DIFF-W8 | Complete Blood Count | Platelets (PLT) | 150 - 450 | x10^3/uL |
| CMP-14-SER | Comprehensive Metabolic | Fasting Serum Glucose | 70 - 99 | mg/dL |
| CMP-14-SER | Comprehensive Metabolic | Serum Creatinine | 0.7 - 1.3 | mg/dL |
| CMP-14-SER | Comprehensive Metabolic | eGFR | 90 - 120 | mL/min/1.73m2 |
| CMP-14-SER | Comprehensive Metabolic | Serum Alanine Aminotransferase | 7 - 56 | U/L |
| LIPID-ST-04 | Lipid Panel | Total Cholesterol | 125 - 200 | mg/dL |
| LIPID-ST-04 | Lipid Panel | HDL Cholesterol | 40 - 60 | mg/dL |
| LIPID-ST-04 | Lipid Panel | LDL Direct | 50 - 100 | mg/dL |
| LIPID-ST-04 | Lipid Panel | Triglycerides | 50 - 150 | mg/dL |

### Status Categorization:
- `OPTIMAL`: Analyte falls strictly between min and max reference boundaries.
- `ELEVATED`: Analyte exceeds upper clinical limit by up to 15%.
- `CRITICAL_HIGH`: Analyte exceeds upper clinical limit by > 15% (triggers alert banner).
- `LOW`: Analyte falls below lower clinical limit.

---

## 6. On-Device AI Clinical Triage Protocol
- Architecture: Token-by-token streaming inference simulated via clinical triage rule engine.
- Patient Data Context: Prompts dynamically inject latest vital signs, active medications, and abnormal lab biomarkers into system context.
- Safety Guardrails:
  - Red Flag Keywords: Immediate detection of acute symptoms (e.g., severe crushing chest pain, sudden left-sided weakness, respiratory distress).
  - Emergency Escalation: Immediate persistent modal prompting patient to contact local emergency medical services (911/112).
  - Explicit Medical Disclaimer: On-device triage is informational and does not replace human clinical judgment.
- Stream State Guarantee: Stream consumer wrapped in defensive `try ... finally` block guaranteeing `isStreaming = false` on completion.

---

## 7. Data Privacy, HIPAA & GDPR Compliance
1. Local Data Encryption: SQLite database file secured with deterministic access controls.
2. Synthetic Clinical Data: All seeded patient profiles, vitals, and physician identities are 100% synthetic, eliminating PHI (Protected Health Information) exposure risks.
3. Offline Autonomy: All biometric ingestion, analysis, and triage operates with zero network dependencies.
4. Export & Redaction: Lab export sheet strips identifiable local tokens prior to simulated sharing.

---

## 8. Viewport & Accessibility Standards
1. 360dp Landscape Viewport Safety:
   - Full compatibility with 800x360 landscape screens.
   - Left-docked compact `NavigationRail` with intrinsic height and scrollable destination list.
   - Dual-pane master-detail presentation with independent vertical scroll controllers.
2. Dynamic Theme Parity:
   - Zero hardcoded colors; all components resolve via `Theme.of(context).colorScheme`.
   - Complete parity between Obsidian Clinical Dark Mode and Crisp Sterile Light Mode.
3. Ergonomic Touch Targets: All buttons, chips, and modal targets meet or exceed 48x48dp touch requirements.
