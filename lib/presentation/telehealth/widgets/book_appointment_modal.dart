import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../data/models/telehealth_doctor_model.dart';
import '../telehealth_notifier.dart';

class BookAppointmentModal extends ConsumerStatefulWidget {
  final TelehealthDoctorModel doctor;

  const BookAppointmentModal({super.key, required this.doctor});

  @override
  ConsumerState<BookAppointmentModal> createState() =>
      _BookAppointmentModalState();
}

class _BookAppointmentModalState extends ConsumerState<BookAppointmentModal> {
  final _formKey = GlobalKey<FormState>();
  final _symptomController = TextEditingController();

  final DateTime _selectedDate = DateTime.now().add(const Duration(hours: 4));
  String _selectedTimeSlot = '10:30 AM';
  String _consultationMode = 'VIDEO_CALL'; // or 'CLINIC_VISIT'
  bool _shareLiveVitals = true;

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:30 AM',
    '11:45 AM',
    '02:15 PM',
    '03:45 PM',
    '05:00 PM',
  ];

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(telehealthNotifierProvider.notifier)
          .bookAppointment(
            doctor: widget.doctor,
            scheduledTime: _selectedDate,
            consultationMode: _consultationMode,
            symptomNotes: _symptomController.text.trim(),
            liveVitalSharing: _shareLiveVitals,
          );

      if (mounted) {
        Navigator.of(context).pop();
        AppFeedback.showSuccess(
          context,
          'Telehealth appointment booked with ${widget.doctor.name}. Synced to SQLite.',
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
                    CircleAvatar(
                      backgroundImage: AssetImage(widget.doctor.avatarPath),
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book Consultation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${widget.doctor.name} (${widget.doctor.specialty})',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'CONSULTATION MODE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('HD Video Call'),
                          ],
                        ),
                        selected: _consultationMode == 'VIDEO_CALL',
                        onSelected: (val) {
                          if (val) {
                            setState(() => _consultationMode = 'VIDEO_CALL');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_hospital_outlined, size: 16),
                            SizedBox(width: 6),
                            Text('Clinic Visit'),
                          ],
                        ),
                        selected: _consultationMode == 'CLINIC_VISIT',
                        onSelected: (val) {
                          if (val) {
                            setState(() => _consultationMode = 'CLINIC_VISIT');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'SELECT TIME SLOT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timeSlots.map((slot) {
                    final isSelected = _selectedTimeSlot == slot;
                    return ChoiceChip(
                      label: Text(slot, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedTimeSlot = slot);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Share Live Clinical Vitals with Doctor'),
                  subtitle: const Text(
                    'Allows doctor to view live CardioCuff BP, GlucoSense CGM & SpO2',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: _shareLiveVitals,
                  onChanged: (val) => setState(() => _shareLiveVitals = val),
                  activeThumbColor: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _symptomController,
                  decoration: const InputDecoration(
                    labelText: 'Chief Complaint & Symptoms *',
                    hintText: 'e.g. Evaluating blood pressure trends, medication follow up',
                  ),
                  maxLines: 2,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please describe chief symptom or consultation purpose';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _confirmBooking,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    'Confirm Booking • \$${widget.doctor.consultationFee.toInt()}',
                  ),
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
