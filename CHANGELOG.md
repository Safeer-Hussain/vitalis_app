# Changelog

All notable changes to the Vitalis Clinical Ecosystem are documented in this file.

## [1.0.1+2] - 2026-11-18

### Added
- **On-Device Small Language Model (SLM) Gemma Integration (Sprint 25)**:
  - Local execution engine (`GemmaClinicalSlmEngine`) supporting 4-bit INT4 quantization (`Q4_K_M`) of Gemma 2B-IT Clinical weights.
  - Multi-tier `ClinicalSafetyClassifier` with immediate escalation protocols for acute cardiovascular/respiratory emergencies (911/112), psychiatric crises (988 lifeline), and unsupervised medication dosage alteration protections.
  - Hardware acceleration delegate selector supporting dynamic switching across Neural Processing Unit (NPU), Graphics Processing Unit (GPU), and CPU delegates with sub-50ms Time-To-First-Token (TTFT).
  - Air-gapped, zero-network runtime verification ensuring zero clinical data exfiltration.
  - `SlmRuntimeInspectorModal` for real-time inspection of inference latency, active acceleration hardware, memory footprint, and safety classifier audit status.
- **GitHub Actions Release & APK Publishing Automation**:
  - Author automated `.github/workflows/release.yml` building Android release APKs and publishing signed GitHub Releases upon tag creation.
- **Static Analysis & Gatekeeper CI Hardening**:
  - Suppressed deprecated Flutter 3.50+ Material notice noise in `analysis_options.yaml` while preserving strict error checking.
  - Enhanced `tool/sprint_gate.dart` with automated `--no-fatal-infos` static analysis validation.

### Changed
- Bumped application version to `1.0.1+2`.
- Updated test helper fakes to support SLM metrics retrieval and safety classification.
- Expanded comprehensive unit test suite with 9 dedicated test cases for SLM Gemma engine and clinical safety classifier.

## [1.0.0+1] - Initial Production Baseline

### Added
- Feature-First Clean Architecture with Obsidian Dark and Crisp Sterile Light dynamic themes.
- Vitals Telemetry with continuous real-time BLE GATT streaming, CardioCuff Pro, and GlucoSense integration.
- Telehealth Consultation Hub with calendar bookings, filterable medical specialists, and video room simulation.
- Clinical Lab Vault with quantitative biomarker range bars and HL7 FHIR R4 clinical interoperability export.
- Digital Prescription Manager with daily medication adherence tracking and refill routing.
- Local SQLite persistence with full offline-first capabilities.
