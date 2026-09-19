import 'profile.dart';

class CallLog {
  final String id;
  final String conversationId;
  final String kind; // 'audio' or 'video'
  final String status; // 'ringing', 'answered', 'missed', 'declined', 'completed'
  final bool outgoing;
  final DateTime startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final Profile? peer;

  CallLog({
    required this.id,
    required this.conversationId,
    required this.kind,
    required this.status,
    required this.outgoing,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.peer,
  });
}
