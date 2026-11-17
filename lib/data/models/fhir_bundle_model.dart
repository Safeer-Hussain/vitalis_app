import 'dart:convert';

class FhirSignatureModel {
  final String type;
  final DateTime when;
  final String who;
  final String targetFormat;
  final String sigFormat;
  final String sha256Hex;
  final String data;

  const FhirSignatureModel({
    this.type = '1.2.840.10065.1.12.1.1',
    required this.when,
    this.who = 'Practitioner/vitalis-clinical-gateway',
    this.targetFormat = 'application/fhir+json',
    this.sigFormat = 'application/signature+json',
    required this.sha256Hex,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': [
        {
          'system': 'urn:iso-astm:E1762-95:2013',
          'code': type,
          'display': "Author's Signature",
        },
      ],
      'when': when.toUtc().toIso8601String(),
      'who': {
        'reference': who,
        'display': 'Vitalis Gateway Clinical Certifier',
      },
      'targetFormat': targetFormat,
      'sigFormat': sigFormat,
      'data': data,
      '_sha256Digest': sha256Hex,
    };
  }

  factory FhirSignatureModel.fromMap(Map<String, dynamic> map) {
    return FhirSignatureModel(
      type: (map['type'] as List<dynamic>?)?.isNotEmpty == true
          ? (map['type'][0]['code'] as String? ?? '1.2.840.10065.1.12.1.1')
          : '1.2.840.10065.1.12.1.1',
      when: DateTime.tryParse(map['when'] as String? ?? '') ?? DateTime.now(),
      who:
          (map['who'] as Map<String, dynamic>?)?['reference'] as String? ??
          'Practitioner/vitalis-clinical-gateway',
      targetFormat: map['targetFormat'] as String? ?? 'application/fhir+json',
      sigFormat: map['sigFormat'] as String? ?? 'application/signature+json',
      sha256Hex: map['_sha256Digest'] as String? ?? '',
      data: map['data'] as String? ?? '',
    );
  }
}

class FhirResourceModel {
  final String fullUrl;
  final String resourceType;
  final String id;
  final Map<String, dynamic> content;

  const FhirResourceModel({
    required this.fullUrl,
    required this.resourceType,
    required this.id,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {'fullUrl': fullUrl, 'resource': content};
  }

  factory FhirResourceModel.fromMap(Map<String, dynamic> map) {
    final resource = Map<String, dynamic>.from(map['resource'] as Map? ?? {});
    return FhirResourceModel(
      fullUrl: map['fullUrl'] as String? ?? 'urn:uuid:${resource['id']}',
      resourceType: resource['resourceType'] as String? ?? 'Unknown',
      id: resource['id'] as String? ?? '',
      content: resource,
    );
  }
}

class FhirBundleModel {
  final String resourceType;
  final String id;
  final String type;
  final DateTime timestamp;
  final FhirSignatureModel signature;
  final List<FhirResourceModel> entries;

  const FhirBundleModel({
    this.resourceType = 'Bundle',
    required this.id,
    this.type = 'collection',
    required this.timestamp,
    required this.signature,
    required this.entries,
  });

  int get totalResources => entries.length;

  int countByType(String type) {
    return entries.where((e) => e.resourceType == type).length;
  }

  Map<String, dynamic> toMap() {
    return {
      'resourceType': resourceType,
      'id': id,
      'meta': {
        'versionId': '1',
        'lastUpdated': timestamp.toUtc().toIso8601String(),
        'profile': ['http://hl7.org/fhir/StructureDefinition/Bundle'],
      },
      'type': type,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'total': entries.length,
      'signature': signature.toMap(),
      'entry': entries.map((e) => e.toMap()).toList(),
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }

  factory FhirBundleModel.fromMap(Map<String, dynamic> map) {
    final entryList = (map['entry'] as List<dynamic>?) ?? [];
    return FhirBundleModel(
      resourceType: map['resourceType'] as String? ?? 'Bundle',
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'collection',
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      signature: FhirSignatureModel.fromMap(
        Map<String, dynamic>.from(map['signature'] as Map? ?? {}),
      ),
      entries: entryList
          .map(
            (e) =>
                FhirResourceModel.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}
