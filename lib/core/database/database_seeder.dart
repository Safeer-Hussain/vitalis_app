import 'package:sqflite/sqflite.dart';

class DatabaseSeeder {
  static Future<void> seedDatabase(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM telehealth_doctors'),
    );
    if (count != null && count > 0) {
      return; // Already seeded
    }

    final now = DateTime.now();

    // 1. Seed 14 Days of Historical Vitals
    final batch = db.batch();
    for (int i = 14; i >= 0; i--) {
      final date = now.subtract(Duration(days: i, hours: (i % 3) * 4));
      final ts = date.millisecondsSinceEpoch;

      final systolic = 118 + ((i * 3) % 11) - 4;
      final diastolic = 77 + ((i * 2) % 9) - 3;
      final map = ((2 * diastolic) + systolic) / 3.0;
      final pulse = 70 + ((i * 5) % 9) - 3;
      final glucose = 104 + ((i * 7) % 19) - 8;
      final glucoseMmol = double.parse((glucose / 18.0182).toStringAsFixed(1));
      final spO2 = 98 - (i % 2);
      final tempC = 36.7 + ((i % 4) * 0.1);

      batch.insert('vitals', {
        'id': 'vital_hist_$i',
        'timestamp': ts,
        'sensor_type': i % 2 == 0 ? 'CARDIO_CUFF' : 'GLUCO_SENSE',
        'systolic': systolic,
        'diastolic': diastolic,
        'mean_arterial_pressure': double.parse(map.toStringAsFixed(1)),
        'pulse_rate': pulse,
        'glucose_mg_dl': glucose,
        'glucose_mmol_l': glucoseMmol,
        'trend_arrow': glucose > 110 ? 'RISING' : 'STABLE',
        'oxygen_saturation': spO2,
        'perfusion_index': 4.2,
        'temperature_celsius': double.parse(tempC.toStringAsFixed(1)),
        'temperature_fahrenheit': double.parse(
          ((tempC * 9 / 5) + 32).toStringAsFixed(1),
        ),
        'irregular_heartbeat': 0,
        'crc32_checksum': 'E49A1F3C',
        'notes': 'Automated clinical sensor sync packet',
      });
    }

    // 2. Seed 21 Board-Certified Specialists
    final specialists = [
      {
        'id': 'doc_01',
        'name': 'Dr. Sarah Chen, MD, FACC',
        'specialty': 'Cardiology',
        'subspecialty': 'Interventional Cardiology & Electrophysiology',
        'hospital': 'St. Jude Academic Heart Institute',
        'rating': 4.96,
        'review_count': 342,
        'consultation_fee': 180.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_sarah_chen.png',
        'bio': 'Board-certified in Cardiovascular Disease and Clinical Cardiac Electrophysiology with 14 years of clinical trial research.',
        'experience_years': 14,
      },
      {
        'id': 'doc_02',
        'name': 'Dr. Marcus Vance, MD, FACE',
        'specialty': 'Endocrinology',
        'subspecialty': 'Metabolic Disorders & Continuous Glucose Tech',
        'hospital': 'Metropolitan Endocrine & Diabetes Center',
        'rating': 4.92,
        'review_count': 288,
        'consultation_fee': 165.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_marcus_vance.png',
        'bio': 'Specialist in insulin resistance optimization, automated closed-loop CGM calibration, and thyroid dysfunctions.',
        'experience_years': 16,
      },
      {
        'id': 'doc_03',
        'name': 'Dr. Elena Rostova, MD',
        'specialty': 'Internal Medicine',
        'subspecialty': 'Preventative Medicine & Multi-System Care',
        'hospital': 'Pacific Health Sciences University Hospital',
        'rating': 4.98,
        'review_count': 512,
        'consultation_fee': 140.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_elena_rostova.png',
        'bio': 'Attending internist specializing in complex clinical triage, polypharmacy reconciliation, and chronic biomarker trend analysis.',
        'experience_years': 18,
      },
      {
        'id': 'doc_04',
        'name': 'Dr. Julian Hayes, MD, PhD',
        'specialty': 'Neurology',
        'subspecialty': 'Cognitive Neurology & Cerebrovascular Health',
        'hospital': 'Johns Hopkins Neurological Institute',
        'rating': 4.91,
        'review_count': 195,
        'consultation_fee': 220.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_julian_hayes.png',
        'bio': 'Dual MD/PhD neurovascular specialist investigating cerebral hemodynamics and autonomic nervous system regulation.',
        'experience_years': 12,
      },
      {
        'id': 'doc_05',
        'name': 'Dr. Aisha Patel, MD, FAAD',
        'specialty': 'Dermatology',
        'subspecialty': 'Dermatopathology & Autoimmune Cutaneous Diseases',
        'hospital': 'Columbia University Medical Center',
        'rating': 4.95,
        'review_count': 418,
        'consultation_fee': 150.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_aisha_patel.png',
        'bio': 'Expert dermatologist treating inflammatory dermatoses, tele-dermatoscopy, and cutaneous manifestation of systemic disease.',
        'experience_years': 11,
      },
      {
        'id': 'doc_06',
        'name': 'Dr. Michael Roberts, MD',
        'specialty': 'Cardiology',
        'subspecialty': 'Advanced Heart Failure & Hemodynamics',
        'hospital': 'Cleveland Clinic Heart Center',
        'rating': 4.89,
        'review_count': 230,
        'consultation_fee': 195.0,
        'available_today': 0,
        'avatar_path': 'assets/images/doctors/dr_sarah_chen.png',
        'bio': 'Pioneer in telemetric pulmonary artery pressure monitoring and non-invasive cardiac output diagnostics.',
        'experience_years': 15,
      },
      {
        'id': 'doc_07',
        'name': 'Dr. Priya Nair, MD',
        'specialty': 'Endocrinology',
        'subspecialty': 'Adrenal & Neuroendocrine Oncology',
        'hospital': 'Mayo Clinic Endocrinology',
        'rating': 4.88,
        'review_count': 167,
        'consultation_fee': 175.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_marcus_vance.png',
        'bio': 'Dedicated endocrinologist providing precision hormonal balancing and metabolic profiling.',
        'experience_years': 13,
      },
      {
        'id': 'doc_08',
        'name': 'Dr. James Wilson, MD',
        'specialty': 'Internal Medicine',
        'subspecialty': 'Clinical Oncology & Primary Care',
        'hospital': 'Princeton Plainsboro Medical Center',
        'rating': 4.94,
        'review_count': 380,
        'consultation_fee': 145.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_elena_rostova.png',
        'bio': 'Compassionate general practitioner with special focus on preventive screening and long-term vitality metrics.',
        'experience_years': 20,
      },
      {
        'id': 'doc_09',
        'name': 'Dr. Allison Cameron, MD',
        'specialty': 'Neurology',
        'subspecialty': 'Neuro-Immunology & Multiple Sclerosis',
        'hospital': 'Northwestern Memorial Hospital',
        'rating': 4.87,
        'review_count': 142,
        'consultation_fee': 210.0,
        'available_today': 0,
        'avatar_path': 'assets/images/doctors/dr_julian_hayes.png',
        'bio': 'Expert in neuro-inflammatory cascades and advanced brain MRI telemetry evaluation.',
        'experience_years': 10,
      },
      {
        'id': 'doc_10',
        'name': 'Dr. Eric Foreman, MD',
        'specialty': 'Dermatology',
        'subspecialty': 'Pediatric & Surgical Dermatology',
        'hospital': 'UCLA Health Dermatology',
        'rating': 4.85,
        'review_count': 210,
        'consultation_fee': 155.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_aisha_patel.png',
        'bio': 'Specializing in rapid cutaneous lesion triaging and cosmetic reconstructive dermatology.',
        'experience_years': 14,
      },
      {
        'id': 'doc_11',
        'name': 'Dr. Ananya Sharma, MD',
        'specialty': 'Cardiology',
        'subspecialty': 'Preventative Cardiovascular Genetics',
        'hospital': 'Boston General Heart Institute',
        'rating': 4.93,
        'review_count': 176,
        'consultation_fee': 185.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_sarah_chen.png',
        'bio': 'Focuses on ApoB, Lp(a), and coronary calcium score biomarker interventions for longevity.',
        'experience_years': 9,
      },
      {
        'id': 'doc_12',
        'name': 'Dr. Robert Sterling, MD',
        'specialty': 'Endocrinology',
        'subspecialty': 'Thyroid Nodules & Pituitary Disease',
        'hospital': 'Stanford Health Care',
        'rating': 4.90,
        'review_count': 320,
        'consultation_fee': 170.0,
        'available_today': 0,
        'avatar_path': 'assets/images/doctors/dr_marcus_vance.png',
        'bio': 'Clinical researcher and professor specializing in ultrasound-guided thyroid diagnostics.',
        'experience_years': 22,
      },
      {
        'id': 'doc_13',
        'name': 'Dr. Lisa Cuddy, MD',
        'specialty': 'Internal Medicine',
        'subspecialty': 'Executive Health & Integrative Diagnostics',
        'hospital': 'Princeton Plainsboro Clinic',
        'rating': 4.97,
        'review_count': 490,
        'consultation_fee': 160.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_elena_rostova.png',
        'bio': 'Senior clinical administrator and practicing internist focusing on comprehensive executive physicals.',
        'experience_years': 24,
      },
      {
        'id': 'doc_14',
        'name': 'Dr. David Kim, MD',
        'specialty': 'Cardiology',
        'subspecialty': 'Echocardiography & Valvular Disease',
        'hospital': 'Cedars-Sinai Medical Center',
        'rating': 4.91,
        'review_count': 215,
        'consultation_fee': 175.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_sarah_chen.png',
        'bio': 'Expert in structural heart disease, strain imaging, and digital telemetry monitoring.',
        'experience_years': 13,
      },
      {
        'id': 'doc_15',
        'name': 'Dr. Clara Oswald, MD',
        'specialty': 'Endocrinology',
        'subspecialty': 'Reproductive Endocrinology & PCOS',
        'hospital': 'Oxford University Hospitals',
        'rating': 4.88,
        'review_count': 184,
        'consultation_fee': 160.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_marcus_vance.png',
        'bio': 'Specialist in insulin sensitization, metabolic reproductive endocrinology, and bone density.',
        'experience_years': 8,
      },
      {
        'id': 'doc_16',
        'name': 'Dr. Thomas Vance, MD',
        'specialty': 'Internal Medicine',
        'subspecialty': 'Geriatric Care & Cognitive Vitality',
        'hospital': 'St. Thomas General Hospital',
        'rating': 4.86,
        'review_count': 260,
        'consultation_fee': 135.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_elena_rostova.png',
        'bio': 'Dedicated to frailty mitigation, functional independence, and clinical pharmacology.',
        'experience_years': 19,
      },
      {
        'id': 'doc_17',
        'name': 'Dr. Gregory House, MD',
        'specialty': 'Neurology',
        'subspecialty': 'Diagnostic Medicine & Rare Neuropathies',
        'hospital': 'Princeton Diagnostic Medicine Dept.',
        'rating': 4.99,
        'review_count': 640,
        'consultation_fee': 300.0,
        'available_today': 0,
        'avatar_path': 'assets/images/doctors/dr_julian_hayes.png',
        'bio': 'World-renowned diagnostician solving complex multi-organ etiologies and neuro-toxicological syndromes.',
        'experience_years': 25,
      },
      {
        'id': 'doc_18',
        'name': 'Dr. Chloe Bennett, MD',
        'specialty': 'Dermatology',
        'subspecialty': 'Mohs Micrographic Surgery & Oncology',
        'hospital': 'Memorial Sloan Kettering Center',
        'rating': 4.94,
        'review_count': 295,
        'consultation_fee': 180.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_aisha_patel.png',
        'bio': 'Fellowship-trained surgical dermatologist with expertise in digital mole mapping and early melanoma detection.',
        'experience_years': 12,
      },
      {
        'id': 'doc_19',
        'name': 'Dr. Sophie Martin, MD',
        'specialty': 'General Practice',
        'subspecialty': 'Family Medicine & Lifestyle Prescriptions',
        'hospital': 'Global Virtual Health Clinic',
        'rating': 4.92,
        'review_count': 310,
        'consultation_fee': 120.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_elena_rostova.png',
        'bio': 'Holistic lifestyle medicine certified physician guiding nutritional and circadian health.',
        'experience_years': 9,
      },
      {
        'id': 'doc_20',
        'name': 'Dr. Raymond Holt, MD',
        'specialty': 'Neurology',
        'subspecialty': 'Sleep Medicine & Circadian Telemetry',
        'hospital': 'Brooklyn Health Sciences Network',
        'rating': 4.90,
        'review_count': 204,
        'consultation_fee': 190.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_julian_hayes.png',
        'bio': 'Specialist in sleep architecture polysomnography, narcolepsy, and central apnea monitoring.',
        'experience_years': 16,
      },
      {
        'id': 'doc_21',
        'name': 'Dr. Benjamin Lin, MD',
        'specialty': 'Dermatology',
        'subspecialty': 'Contact Dermatitis & Patch Testing',
        'hospital': 'Toronto Western Dermatology',
        'rating': 4.89,
        'review_count': 175,
        'consultation_fee': 145.0,
        'available_today': 1,
        'avatar_path': 'assets/images/doctors/dr_aisha_patel.png',
        'bio': 'Clinical immunodermatologist assessing environmental allergens and chronic eczema regimens.',
        'experience_years': 10,
      },
    ];

    for (final doc in specialists) {
      batch.insert('telehealth_doctors', doc);
    }

    // 3. Seed Active Telehealth Appointments
    batch.insert('telehealth_appointments', {
      'id': 'apt_001',
      'doctor_id': 'doc_01',
      'doctor_name': 'Dr. Sarah Chen, MD, FACC',
      'specialty': 'Cardiology',
      'scheduled_time': now
          .add(const Duration(hours: 2, minutes: 30))
          .millisecondsSinceEpoch,
      'consultation_mode': 'VIDEO_CALL',
      'symptom_notes': 'Follow-up review of 14-day ambulatory blood pressure telemetry and nocturnal dipping profile.',
      'status': 'SCHEDULED',
      'live_vital_sharing': 1,
    });

    batch.insert('telehealth_appointments', {
      'id': 'apt_002',
      'doctor_id': 'doc_02',
      'doctor_name': 'Dr. Marcus Vance, MD, FACE',
      'specialty': 'Endocrinology',
      'scheduled_time': now
          .add(const Duration(days: 3, hours: 4))
          .millisecondsSinceEpoch,
      'consultation_mode': 'VIDEO_CALL',
      'symptom_notes': 'Evaluation of GlucoSense CGM continuous glucose time-in-range (94.6%) and fasting insulin.',
      'status': 'SCHEDULED',
      'live_vital_sharing': 1,
    });

    // 4. Seed 5 Clinical Lab Panels & Biomarkers
    final panels = [
      {
        'id': 'lab_cbc_01',
        'title': 'Complete Blood Count (CBC) with Differential',
        'panel_code': 'CBC-DIFF-W8',
        'category': 'Hematology',
        'collection_date': now
            .subtract(const Duration(days: 4))
            .millisecondsSinceEpoch,
        'ordering_physician': 'Dr. Elena Rostova, MD',
        'status': 'FINAL',
        'is_bookmarked': 1,
        'clinical_notes': 'Erythrocyte and platelet indices within normal parameters. Mild reactive leukocyte count consistent with recent seasonal inoculation.',
      },
      {
        'id': 'lab_lip_02',
        'title': 'Advanced Cardiovascular Lipid Biomarker Panel',
        'panel_code': 'LIPID-ADV-X4',
        'category': 'Cardiovascular',
        'collection_date': now
            .subtract(const Duration(days: 6))
            .millisecondsSinceEpoch,
        'ordering_physician': 'Dr. Sarah Chen, MD, FACC',
        'status': 'FINAL',
        'is_bookmarked': 1,
        'clinical_notes': 'ApoB and Non-HDL cholesterol demonstrating favorable response to current 20mg Atorvastatin regimen. HDL remains optimal.',
      },
      {
        'id': 'lab_met_03',
        'title': 'Glycated Hemoglobin (HbA1c) & Metabolic Panel',
        'panel_code': 'METAB-HBA1C-9',
        'category': 'Endocrine',
        'collection_date': now
            .subtract(const Duration(days: 10))
            .millisecondsSinceEpoch,
        'ordering_physician': 'Dr. Marcus Vance, MD, FACE',
        'status': 'FINAL',
        'is_bookmarked': 0,
        'clinical_notes': 'HbA1c steady at 5.5%, corresponding to an estimated average glucose (eAG) of 111 mg/dL. Renal filtration eGFR > 90.',
      },
      {
        'id': 'lab_tsh_04',
        'title': 'High-Sensitivity Thyroid TSH & Free Thyroxine Panel',
        'panel_code': 'THYROID-TSH-3',
        'category': 'Endocrine',
        'collection_date': now
            .subtract(const Duration(days: 18))
            .millisecondsSinceEpoch,
        'ordering_physician': 'Dr. Marcus Vance, MD, FACE',
        'status': 'FINAL',
        'is_bookmarked': 0,
        'clinical_notes': 'TSH tightly regulated at 1.85 mIU/L on current 50mcg Levothyroxine dosing.',
      },
      {
        'id': 'lab_vit_05',
        'title': '25-Hydroxy Vitamin D3 & Micronutrient Assay',
        'panel_code': 'VIT-D3-ASSAY',
        'category': 'Nutritional',
        'collection_date': now
            .subtract(const Duration(days: 22))
            .millisecondsSinceEpoch,
        'ordering_physician': 'Dr. Elena Rostova, MD',
        'status': 'FINAL',
        'is_bookmarked': 1,
        'clinical_notes': 'Serum 25-OH Vitamin D restored to optimal physiological threshold (48 ng/mL) following 2000 IU daily supplementation.',
      },
    ];

    for (final panel in panels) {
      batch.insert('lab_reports', panel);
    }

    // Seed Detailed Biomarkers for each panel
    final biomarkersList = [
      // CBC
      {
        'id': 'bm_01',
        'report_id': 'lab_cbc_01',
        'name': 'White Blood Cells (WBC)',
        'code': 'WBC',
        'value': 6.8,
        'unit': 'x10^3/uL',
        'min_range': 4.5,
        'max_range': 11.0,
        'clinical_status': 'OPTIMAL',
        'historical_value': 7.1,
        'interpretation': 'Normal immunological baseline.',
      },
      {
        'id': 'bm_02',
        'report_id': 'lab_cbc_01',
        'name': 'Hemoglobin (Hgb)',
        'code': 'HGB',
        'value': 15.2,
        'unit': 'g/dL',
        'min_range': 13.8,
        'max_range': 17.2,
        'clinical_status': 'OPTIMAL',
        'historical_value': 14.9,
        'interpretation': 'Normocytic, normochromic oxygen delivery capacity.',
      },
      {
        'id': 'bm_03',
        'report_id': 'lab_cbc_01',
        'name': 'Platelets',
        'code': 'PLT',
        'value': 245.0,
        'unit': 'x10^3/uL',
        'min_range': 150.0,
        'max_range': 450.0,
        'clinical_status': 'OPTIMAL',
        'historical_value': 238.0,
        'interpretation': 'Robust primary hemostasis reserve.',
      },
      // Lipid
      {
        'id': 'bm_04',
        'report_id': 'lab_lip_02',
        'name': 'Total Cholesterol',
        'code': 'CHOL',
        'value': 168.0,
        'unit': 'mg/dL',
        'min_range': 125.0,
        'max_range': 200.0,
        'clinical_status': 'OPTIMAL',
        'historical_value': 188.0,
        'interpretation': 'Significant decrease following lipid therapy.',
      },
      {
        'id': 'bm_05',
        'report_id': 'lab_lip_02',
        'name': 'LDL Direct (Atherogenic)',
        'code': 'LDL',
        'value': 82.0,
        'unit': 'mg/dL',
        'min_range': 50.0,
        'max_range': 100.0,
        'clinical_status': 'OPTIMAL',
        'historical_value': 108.0,
        'interpretation':
            'Atherogenic particle clearance meeting primary prevention target.',
      },
      {
        'id': 'bm_06',
        'report_id': 'lab_lip_02',
        'name': 'HDL Cholesterol (Protective)',
        'code': 'HDL',
        'value': 62.0,
        'unit': 'mg/dL',
        'min_range': 40.0,
        'max_range': 80.0,
        'clinical_status': 'OPTIMAL',
        'historical_value': 59.0,
        'interpretation': 'Cardioprotective reverse cholesterol transport.',
      },
      {
        'id': 'bm_07',
        'report_id': 'lab_lip_02',
        'name': 'Serum Triglycerides',
        'code': 'TRIG',
        'value': 118.0,
        'unit': 'mg/dL',
        'min_range': 40.0,
        'max_range': 150.0,
        'clinical_status': 'OPTIMAL',
        'historical_value': 135.0,
        'interpretation': 'Normal post-absorptive lipid metabolism.',
      },
      // HbA1c
      {
        'id': 'bm_08',
        'report_id': 'lab_met_03',
        'name': 'Hemoglobin A1c (Glycated)',
        'code': 'HBA1C',
        'value': 5.5,
        'unit': '%',
        'min_range': 4.0,
        'max_range': 5.6,
        'clinical_status': 'OPTIMAL',
        'historical_value': 5.7,
        'interpretation': 'Normal non-diabetic glycemic regulation over preceding 90-day cycle.',
      },
      {
        'id': 'bm_09',
        'report_id': 'lab_met_03',
        'name': 'Fasting Blood Glucose',
        'code': 'GLUC_FAST',
        'value': 94.0,
        'unit': 'mg/dL',
        'min_range': 70.0,
        'max_range': 99.0,
        'clinical_status': 'OPTIMAL',
        'historical_value': 102.0,
        'interpretation': 'Normoglycemic fasting state.',
      },
      // Thyroid
      {
        'id': 'bm_10',
        'report_id': 'lab_tsh_04',
        'name': 'Thyroid Stimulating Hormone (TSH)',
        'code': 'TSH',
        'value': 1.85,
        'unit': 'mIU/L',
        'min_range': 0.45,
        'max_range': 4.5,
        'clinical_status': 'OPTIMAL',
        'historical_value': 2.45,
        'interpretation':
            'Euthyroid pituitary-thyroid feedback axis equilibrium.',
      },
      // Vitamin D3
      {
        'id': 'bm_11',
        'report_id': 'lab_vit_05',
        'name': '25-Hydroxy Vitamin D3',
        'code': 'VIT_D',
        'value': 48.0,
        'unit': 'ng/mL',
        'min_range': 30.0,
        'max_range': 100.0,
        'clinical_status': 'OPTIMAL',
        'historical_value': 26.0,
        'interpretation': 'Deficiency successfully reversed to robust immuno-modulatory zone.',
      },
    ];

    for (final bm in biomarkersList) {
      batch.insert('biomarkers', bm);
    }

    // 5. Seed Active Prescriptions
    final prescriptions = [
      {
        'id': 'rx_01',
        'medication_name': 'Lisinopril',
        'dosage': '10 mg Oral Tablet',
        'instructions': 'Take 1 tablet every morning with water. Monitor resting blood pressure.',
        'frequency': 'Morning',
        'pills_remaining': 24,
        'total_pills': 30,
        'doses_taken_today': 1,
        'daily_target_doses': 1,
        'prescribing_doctor': 'Dr. Sarah Chen, MD, FACC',
        'refill_status': 'NORMAL',
        'last_taken_timestamp': now
            .subtract(const Duration(hours: 4))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'rx_02',
        'medication_name': 'Metformin HCl ER',
        'dosage': '500 mg Extended-Release Tablet',
        'instructions':
            'Take 1 tablet twice daily with morning and evening meals.',
        'frequency': 'Morning & Evening',
        'pills_remaining': 48,
        'total_pills': 60,
        'doses_taken_today': 1,
        'daily_target_doses': 2,
        'prescribing_doctor': 'Dr. Marcus Vance, MD, FACE',
        'refill_status': 'NORMAL',
        'last_taken_timestamp': now
            .subtract(const Duration(hours: 4))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'rx_03',
        'medication_name': 'Atorvastatin Calcium',
        'dosage': '20 mg Oral Tablet',
        'instructions': 'Take 1 tablet at bedtime for lipid reduction.',
        'frequency': 'Night',
        'pills_remaining': 8,
        'total_pills': 30,
        'doses_taken_today': 0,
        'daily_target_doses': 1,
        'prescribing_doctor': 'Dr. Sarah Chen, MD, FACC',
        'refill_status': 'NORMAL',
        'last_taken_timestamp': now
            .subtract(const Duration(hours: 19))
            .millisecondsSinceEpoch,
      },
      {
        'id': 'rx_04',
        'medication_name': 'Cholecalciferol (Vitamin D3)',
        'dosage': '2,000 IU Capsule',
        'instructions':
            'Take 1 capsule every morning with a meal containing dietary fat.',
        'frequency': 'Morning',
        'pills_remaining': 52,
        'total_pills': 60,
        'doses_taken_today': 1,
        'daily_target_doses': 1,
        'prescribing_doctor': 'Dr. Elena Rostova, MD',
        'refill_status': 'NORMAL',
        'last_taken_timestamp': now
            .subtract(const Duration(hours: 4))
            .millisecondsSinceEpoch,
      },
    ];

    for (final rx in prescriptions) {
      batch.insert('prescriptions', rx);
    }

    // 6. Seed Initial AI Triage Welcome Message
    batch.insert('ai_triage_messages', {
      'id': 'triage_init_01',
      'sender': 'AI',
      'content': 'Welcome to the Vitalis AI Clinical Triage Companion. I continuously correlate your continuous telemetry (CardioCuff BP, GlucoSense CGM, OxyPulse SpO2), diagnostic lab panels, and active medications. Select a quick action below or describe your symptoms for real-time differential clinical analysis.',
      'timestamp': now.millisecondsSinceEpoch,
      'clinical_summary': 'System ready for interactive diagnostic triage.',
    });

    await batch.commit(noResult: true);
  }
}
