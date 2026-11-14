import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_feedback.dart';
import '../prescriptions_notifier.dart';

class AddPrescriptionModal extends ConsumerStatefulWidget {
  const AddPrescriptionModal({super.key});

  @override
  ConsumerState<AddPrescriptionModal> createState() =>
      _AddPrescriptionModalState();
}

class _AddPrescriptionModalState extends ConsumerState<AddPrescriptionModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _pillsCountController = TextEditingController(text: '30');
  final _targetDosesController = TextEditingController(text: '1');
  final _doctorController = TextEditingController(text: 'Dr. Sarah Chen, MD');

  String _frequency = 'Morning';
  final List<String> _frequencies = [
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
    'Morning & Evening',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _pillsCountController.dispose();
    _targetDosesController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  Future<void> _submitPrescription() async {
    if (_formKey.currentState?.validate() ?? false) {
      final pills = int.tryParse(_pillsCountController.text) ?? 30;
      final target = int.tryParse(_targetDosesController.text) ?? 1;

      await ref
          .read(prescriptionsNotifierProvider.notifier)
          .addPrescription(
            medicationName: _nameController.text.trim(),
            dosage: _dosageController.text.trim(),
            instructions: _instructionsController.text.trim(),
            frequency: _frequency,
            pillsCount: pills,
            dailyTargetDoses: target,
            prescribingDoctor: _doctorController.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop();
        AppFeedback.showSuccess(
          context,
          'Added ${_nameController.text.trim()} to active medication ledger.',
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
                        Icons.medication_rounded,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add Prescription',
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
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medication Name *',
                    hintText: 'e.g. Amlodipine Besylate',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Medication name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dosageController,
                        decoration: const InputDecoration(
                          labelText: 'Dosage Form *',
                          hintText: 'e.g. 5 mg Oral Tablet',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Dosage required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _frequency,
                        decoration: const InputDecoration(
                          labelText: 'Frequency *',
                        ),
                        items: _frequencies.map((f) {
                          return DropdownMenuItem(value: f, child: Text(f));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _frequency = val);
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
                        controller: _pillsCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pills Remaining *',
                          hintText: '30',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final n = int.tryParse(val);
                          if (n == null || n < 1 || n > 500) {
                            return '1-500 pills';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _targetDosesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Doses / Day *',
                          hintText: '1',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final n = int.tryParse(val);
                          if (n == null || n < 1 || n > 6) {
                            return '1-6 doses';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _doctorController,
                  decoration: const InputDecoration(
                    labelText: 'Prescribing Physician *',
                    hintText: 'e.g. Dr. Sarah Chen, MD',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Physician name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Administration Instructions *',
                    hintText: 'e.g. Take once daily in the morning with water',
                  ),
                  maxLines: 2,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Instructions are required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submitPrescription,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save to Medication Vault'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
