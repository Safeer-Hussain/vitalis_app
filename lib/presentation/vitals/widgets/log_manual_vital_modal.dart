import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_feedback.dart';
import '../vitals_notifier.dart';

class LogManualVitalModal extends ConsumerStatefulWidget {
  const LogManualVitalModal({super.key});

  @override
  ConsumerState<LogManualVitalModal> createState() =>
      _LogManualVitalModalState();
}

class _LogManualVitalModalState extends ConsumerState<LogManualVitalModal> {
  final _formKey = GlobalKey<FormState>();

  final _systolicController = TextEditingController(text: '120');
  final _diastolicController = TextEditingController(text: '80');
  final _pulseController = TextEditingController(text: '72');
  final _glucoseController = TextEditingController(text: '105');
  final _spO2Controller = TextEditingController(text: '98');
  final _tempController = TextEditingController(text: '36.8');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _glucoseController.dispose();
    _spO2Controller.dispose();
    _tempController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitVital() async {
    if (_formKey.currentState?.validate() ?? false) {
      final sys = int.tryParse(_systolicController.text);
      final dia = int.tryParse(_diastolicController.text);
      final pulse = int.tryParse(_pulseController.text);
      final glucose = int.tryParse(_glucoseController.text);
      final spo2 = int.tryParse(_spO2Controller.text);
      final temp = double.tryParse(_tempController.text);

      await ref
          .read(vitalsNotifierProvider.notifier)
          .logManualVital(
            systolic: sys,
            diastolic: dia,
            pulseRate: pulse,
            glucoseMgDl: glucose,
            oxygenSaturation: spo2,
            temperatureCelsius: temp,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : 'Manual patient log entry',
          );

      if (mounted) {
        Navigator.of(context).pop();
        AppFeedback.showSuccess(
          context,
          'Vital signs recorded and persisted to encrypted SQLite vault.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_chart_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Log Manual Vital Sign',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _systolicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Systolic (mmHg) *',
                          hintText: '120',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final n = int.tryParse(val);
                          if (n == null || n < 70 || n > 250) {
                            return 'Range: 70-250';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _diastolicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Diastolic (mmHg) *',
                          hintText: '80',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final n = int.tryParse(val);
                          if (n == null || n < 40 || n > 150) {
                            return 'Range: 40-150';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pulseController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pulse (bpm) *',
                          hintText: '72',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final n = int.tryParse(val);
                          if (n == null || n < 30 || n > 220) {
                            return 'Range: 30-220';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _glucoseController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Glucose (mg/dL) *',
                          hintText: '100',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final n = int.tryParse(val);
                          if (n == null || n < 40 || n > 500) {
                            return 'Range: 40-500';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _spO2Controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Oxygen SpO2 (%) *',
                          hintText: '98',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final n = int.tryParse(val);
                          if (n == null || n < 70 || n > 100) {
                            return 'Range: 70-100';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _tempController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Body Temp (°C) *',
                          hintText: '36.8',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final n = double.tryParse(val);
                          if (n == null || n < 34.0 || n > 42.0) {
                            return 'Range: 34-42°C';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Symptoms or Notes (Optional)',
                    hintText: 'e.g. Post-prandial reading, mild fatigue',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _submitVital,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save Vital to Encrypted Vault'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
