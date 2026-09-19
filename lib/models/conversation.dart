import 'profile.dart';
import 'message.dart';

class Conversation {
  final String id;
  final String createdBy;
  final int disappearAfterSeconds;
  final DateTime lastMessageAt;
  final Profile? other;
  final Message? lastMessage;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.createdBy,
    this.disappearAfterSeconds = 0,
    required this.lastMessageAt,
    this.other,
    this.lastMessage,
    this.unreadCount = 0,
  });
}
