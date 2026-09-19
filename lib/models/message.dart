class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final String kind; // 'text', 'image', 'snap', 'voice', 'file', 'call'
  final String? mediaPath;
  final String? mediaMime;
  final String? mediaName;
  final int? mediaSize;
  final int? mediaDuration;
  final String? callId;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.kind = 'text',
    this.mediaPath,
    this.mediaMime,
    this.mediaName,
    this.mediaSize,
    this.mediaDuration,
    this.callId,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
  });

  bool isFromMe(String myUserId) => senderId == myUserId;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String? ?? '',
      kind: json['kind'] as String? ?? 'text',
      mediaPath: json['media_path'] as String?,
      mediaMime: json['media_mime'] as String?,
      mediaName: json['media_name'] as String?,
      mediaSize: json['media_size'] as int?,
      mediaDuration: json['media_duration'] as int?,
      callId: json['call_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at'] as String) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'body': body,
      'kind': kind,
      'media_path': mediaPath,
      'media_mime': mediaMime,
      'media_name': mediaName,
      'media_size': mediaSize,
      'media_duration': mediaDuration,
      'call_id': callId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
