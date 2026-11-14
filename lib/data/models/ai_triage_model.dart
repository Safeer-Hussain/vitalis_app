class AiTriageMessageModel {
  final String id;
  final String sender; // 'USER' | 'AI'
  final String content;
  final DateTime timestamp;
  final String? clinicalSummary;
  final bool isStreaming;

  const AiTriageMessageModel({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.clinicalSummary,
    this.isStreaming = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'clinical_summary': clinicalSummary,
    };
  }

  factory AiTriageMessageModel.fromMap(Map<String, dynamic> map) {
    return AiTriageMessageModel(
      id: map['id'] as String,
      sender: map['sender'] as String,
      content: map['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      clinicalSummary: map['clinical_summary'] as String?,
      isStreaming: false,
    );
  }

  AiTriageMessageModel copyWith({
    String? id,
    String? sender,
    String? content,
    DateTime? timestamp,
    String? clinicalSummary,
    bool? isStreaming,
  }) {
    return AiTriageMessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      clinicalSummary: clinicalSummary ?? this.clinicalSummary,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
