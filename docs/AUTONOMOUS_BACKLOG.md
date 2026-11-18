# Vitalis Autonomous Engineering Backlog
## 25-Day Production Sprint Roadmap

This autonomous roadmap provides daily engineering sprints for continuous iteration, compliance enhancements, telemetry drivers, and clinical capabilities.

---

### Sprint 1: Project Foundation, Git Remotes, Clean Architecture Setup
- Status: COMPLETED
- Scope: Establish repository root structure, configure dual git remotes (`origin` and `vitalis_app`), configure Android Gradle SDK 36, and establish Feature-First Clean Architecture directories.
- Acceptance Criteria:
  1. `git remote -v` verifies authenticated push and fetch for `origin` and `vitalis_app`.
  2. `compileSdk = 36`, `targetSdk = 36`, `minSdk = 21` configured in `build.gradle.kts`.
  3. `EnableImpeller = false` declared in `AndroidManifest.xml`.
  4. Core modules (`core/`, `data/`, `domain/`, `presentation/`) initialized.

---

### Sprint 2: Native Medical Sensor Bridge & Platform Channels
- Status: COMPLETED
- Scope: Implement Kotlin and Swift platform channels for MethodChannel `com.safeer.vitalis/medical_devices` and EventChannel `com.safeer.vitalis/clinical_telemetry`.
- Acceptance Criteria:
  1. Device scanning, pairing, disconnection, and calibration methods functional.
  2. 2000ms clinical packet streaming for CardioCuff Pro, GlucoSense CGM, and OxyPulse Clinical.
  3. CRC32 checksum verification integrated on incoming telemetry packets.

---

### Sprint 3: Encrypted Local Clinical Vault & Database Seeding
- Status: COMPLETED
- Scope: Construct `AppDatabase` utilizing SQLite (`sqflite`), create normalized clinical tables, and implement `DatabaseSeeder`.
- Acceptance Criteria:
  1. Tables created: `vitals`, `doctors`, `appointments`, `lab_reports`, `biomarkers`, `prescriptions`, `ai_chat_history`.
  2. 14 days of historical vitals, 21 specialists, 5 lab panels, and 4 prescriptions seeded deterministically.
  3. Desktop FFI database factory configured for unit and widget test environments.

---

### Sprint 4: Unified Clinical Design System & Dark/Light Parity
- Status: COMPLETED
- Scope: Build `AppTheme` with Obsidian Clinical Dark and Crisp Sterile Light color schemes, zero hardcoded colors, and persistent `themeModeProvider`.
- Acceptance Criteria:
  1. Zero raw `Colors.black`, `Colors.white`, or un-themed hex colors in presentation layer.
  2. Instant reactive theme switching across all 5 navigation tabs.
  3. Floating rounded feedback snackbars in `AppFeedback` with zero emojis.

---

### Sprint 5: Responsive AdaptiveScaffold & 360dp Landscape Viewport
- Status: COMPLETED
- Scope: Build `AdaptiveScaffold` supporting portrait `NavigationBar` and landscape compact `NavigationRail` with two-pane master-detail support.
- Acceptance Criteria:
  1. Zero `RenderFlex` overflow errors on 800x360 landscape screens.
  2. Compact landscape `AppBar` (`toolbarHeight: 36`).
  3. NavigationRail wrapped with scrollable clamp physics and intrinsic height.

---

### Sprint 6: Clinical Vitals Cockpit & Real-Time Telemetry Card
- Status: COMPLETED
- Scope: Implement Vitals Cockpit module with live telemetry stream consumption, sensor connection badge, and interactive manual vital modal.
- Acceptance Criteria:
  1. Real-time updates on BP, MAP, Glucose, SpO2, and Core Body Temp.
  2. Sensor pairing modal supporting calibration and signal strength indicator.
  3. Manual vital logging with strict range validation and immediate database persistence.

---

### Sprint 7: Longitudinal Hemodynamic & Glycemic Trend Charts
- Status: COMPLETED
- Scope: Develop `VitalsTrendChart` utilizing `fl_chart` for 14-day systolic/diastolic blood pressure curves and continuous glucose monitoring trends.
- Acceptance Criteria:
  1. Full-width stretch layout with zero clipping on mobile and tablet.
  2. Interactive toggle between Blood Pressure (mmHg) and CGM Glucose (mg/dL).
  3. Min/Max clinical benchmark threshold lines rendered cleanly.

---

### Sprint 8: Board-Certified Telehealth Hub & Doctor Directory
- Status: COMPLETED
- Scope: Build Telehealth module displaying searchable doctor directory, specialty filters, doctor credentials, and appointment booking modal.
- Acceptance Criteria:
  1. 21 specialists filterable by specialty (Cardiology, Endocrinology, Neurology, Internal Medicine).
  2. Booking modal with date picker, slot selection, and consultation mode choice (Video Call vs Clinic Visit).
  3. Active appointment cards with cancellation confirmation dialogue.

---

### Sprint 9: Simulated HD Video Consultation Interface
- Status: COMPLETED
- Scope: Build `SimulatedConsultationSheet` modal representing active bidirectional telehealth video appointment.
- Acceptance Criteria:
  1. Controls for microphone mute, camera toggle, and consultation end.
  2. Real-time simulated doctor vitals observation notes overlay.
  3. Seamless return to appointment dashboard upon call completion.

---

### Sprint 10: Laboratory Diagnostics Vault & Multi-Panel Viewer
- Status: COMPLETED
- Scope: Build Lab Diagnostics module displaying categorized laboratory panels (Hematology, Metabolic, Lipids).
- Acceptance Criteria:
  1. Panel cards showing specimen accession date, ordering physician, and status tag.
  2. Bookmark toggle with immediate persistence in local SQLite vault.
  3. Search filter by panel code and diagnostic category.

---

### Sprint 11: Quantitative Biomarker Range Bars & Clinical Breakdown
- Status: COMPLETED
- Scope: Build `BiomarkerRangeBar` showing patient analyte value positioned relative to lower and upper clinical reference boundaries.
- Acceptance Criteria:
  1. Color-coded clinical status indicators (Optimal, Elevated, Critical High, Low).
  2. Analyte detail bottom sheet displaying clinical significance and recommendations.
  3. Zero text clipping across narrow master-detail columns.

---

### Sprint 12: Laboratory Report PDF Generation & Sharing Module
- Status: COMPLETED
- Scope: Build `ShareExportLabSheet` modal allowing export simulation of clinical laboratory summaries.
- Acceptance Criteria:
  1. Clinical header with synthetic patient accession ID and redaction notices.
  2. Formatted analyte table ready for clinical handoff.
  3. Direct action triggers for export and patient vault synchronization.

---

### Sprint 13: Digital Prescription Manager & Medication Reminders
- Status: COMPLETED
- Scope: Build Prescriptions module showing active medications, dosages, remaining pill counters, and refill statuses.
- Acceptance Criteria:
  1. Prescription card displaying schedule, frequency, and prescribing doctor.
  2. One-tap "Take Dose" action decrementing pill count and updating daily target adherence.
  3. New prescription modal with validation for medication name, dosage, and frequency.

---

### Sprint 14: Daily Medication Adherence Progress Ring
- Status: COMPLETED
- Scope: Build `AdherenceRingWidget` rendering animated circular progress indicator of doses taken versus scheduled doses.
- Acceptance Criteria:
  1. Dynamic percentage calculation based on active prescription schedule.
  2. Color interpolation based on completion tier.
  3. Reactive re-render upon recording medication dose.

---

### Sprint 15: Prescription Refill Automation & Pharmacy Routing
- Status: COMPLETED
- Scope: Build `RequestRefillSheet` modal enabling patient-initiated refill requests.
- Acceptance Criteria:
  1. Preferred pharmacy selector with operating hours and address.
  2. Urgent vs standard refill urgency selection.
  3. Prescription status transition to `REFILL_REQUESTED` with feedback alert.

---

### Sprint 16: On-Device AI Clinical Triage & Token Streaming
- Status: COMPLETED
- Scope: Implement AI Clinical Triage assistant with simulated token streaming, clinical prompt shortcuts, and multi-modal patient context ingestion.
- Acceptance Criteria:
  1. Token streaming simulation with `try ... finally` guarantee resetting `isStreaming = false`.
  2. Injection of patient vitals and active medications into triage context.
  3. Shortcut chips for common clinical inquiries (chest pain, elevated glucose, missed medication).

---

### Sprint 17: Emergency Triage Protocol & Urgent Medical Escalation
- Status: COMPLETED
- Scope: Integrate emergency keyword detection within triage engine to flag acute emergencies.
- Acceptance Criteria:
  1. Immediate detection of high-risk red-flag symptoms.
  2. High-visibility emergency intervention banner with direct dial shortcut.
  3. Persistent medical disclaimer footer.

---

### Sprint 18: Recruiter Debug Drawer & Offline Simulation Interceptor
- Status: COMPLETED
- Scope: Construct `RecruiterDebugDrawer` accessible via long-press on version number in Settings, paired with `MockClinicalInterceptor`.
- Acceptance Criteria:
  1. Configurable network latency slider (400ms - 850ms).
  2. HTTP 503 error simulation toggle triggering offline recovery banners.
  3. Simulated abnormal vital alert injection button.

---

### Sprint 19: Emergency Medical In Case of Emergency (ICE) Card
- Status: COMPLETED
- Scope: Build `EmergencyIceModal` accessible from Settings providing first responders with critical clinical data.
- Acceptance Criteria:
  1. Display of blood type, confirmed allergies, emergency contacts, and organ donor status.
  2. Inline editing with input validation and instant SQLite persistence.
  3. High-contrast clinical alert card styling.

---

### Sprint 20: Comprehensive Automated Unit & Widget Test Suite
- Status: COMPLETED
- Scope: Author complete test suite verifying notifiers, repository fakes, hero tag safety, landscape layouts, and theme switching.
- Acceptance Criteria:
  1. Minimum 14 passing unit and widget tests (19 implemented and passing).
  2. Zero unhandled exceptions or duplicate hero tag errors.
  3. Verified landscape viewport stability at 800x360dp.

---

### Sprint 21: Quality Gatekeeper Tool & Static Analysis Enforcement
- Status: COMPLETED
- Scope: Author `tool/sprint_gate.dart` automating dependencies, formatting, static analysis, test suite, and optional ADB logcat audit.
- Acceptance Criteria:
  1. Executable with `dart run tool/sprint_gate.dart`.
  2. Immediate exit on any non-zero exit code or formatting violation.
  3. Formatted terminal quality gate summary report.

---

### Sprint 22: GitHub Actions CI/CD Pipeline
- Status: COMPLETED
- Scope: Create `.github/workflows/ci.yml` running on Ubuntu with Java 17 and stable Flutter.
- Acceptance Criteria:
  1. Triggers on push and pull request to `main`.
  2. Executes `pub get`, `dart format`, `flutter analyze`, and `flutter test --coverage`.
  3. Guaranteed pipeline failure on any violation.

---

### Sprint 23: Bluetooth Low Energy (BLE) GATT Direct Peripheral Integration
- Status: COMPLETED
- Scope: Expand native Android and iOS sensor bridges to support direct physical BLE GATT peripheral scanning via native CoreBluetooth and Android BluetoothLeScanner.
- Acceptance Criteria:
  1. Native peripheral discovery with service UUID filtering (`0x180D` Heart Rate, `0x1810` Blood Pressure, `0x1808` Glucose).
  2. Automatic reconnect with exponential backoff on connection drop.
  3. Background telemetry ingestion with foreground service notification on Android.

---

### Sprint 24: FHIR DSTU3 / R4 Clinical Data Export & Interoperability
- Status: COMPLETED
- Scope: Implement Fast Healthcare Interoperability Resources (FHIR) standard export for patient observations, diagnostic reports, and medication statements.
- Acceptance Criteria:
  1. JSON schema validation against HL7 FHIR Release 4 specification.
  2. Export endpoints for `Observation` (Vitals), `DiagnosticReport` (Labs), and `MedicationStatement` (Prescriptions).
  3. Cryptographic signature generation for exported clinical packages.

---

### Sprint 25: On-Device Small Language Model (SLM) Gemma Integration
- Status: COMPLETED
- Scope: Incorporate TensorFlow Lite / Mediapipe LLM Inference runtime for true on-device quantized Gemma 2B execution.
- Acceptance Criteria:
  1. On-device weights loading with zero network transmission.
  2. Sub-50ms time-to-first-token inference on modern physical mobile NPU/GPU.
  3. Strict clinical safety classifier gating all model outputs.
