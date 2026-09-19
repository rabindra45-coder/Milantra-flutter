import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/profile.dart';
import 'supabase_service.dart';

class ChatService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;
  List<Conversation> conversations = [];
  bool isLoading = false;

  Future<void> loadConversations() async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;
    isLoading = true;
    notifyListeners();

    try {
      final partRows = await _client
          .from('conversation_participants')
          .select('conversation_id, last_read_at')
          .eq('user_id', myId);

      final convIds = (partRows as List).map((r) => r['conversation_id'] as String).toList();
      if (convIds.isEmpty) {
        conversations = [];
        isLoading = false;
        notifyListeners();
        return;
      }

      final convRows = await _client
          .from('conversations')
          .select('id, created_by, disappear_after_seconds, last_message_at')
          .inFilter('id', convIds)
          .order('last_message_at', ascending: false);

      final allParticipants = await _client
          .from('conversation_participants')
          .select('conversation_id, user_id')
          .inFilter('conversation_id', convIds)
          .neq('user_id', myId);

      final otherUserIds = (allParticipants as List).map((p) => p['user_id'] as String).toSet().toList();

      final profileRows = await _client
          .from('profiles')
          .select()
          .inFilter('id', otherUserIds);

      final profileMap = {
        for (var p in (profileRows as List)) p['id'] as String: Profile.fromJson(p)
      };

      final convMapOther = <String, Profile>{};
      for (var p in allParticipants) {
        final uid = p['user_id'] as String;
        if (profileMap.containsKey(uid)) {
          convMapOther[p['conversation_id'] as String] = profileMap[uid]!;
        }
      }

      List<Conversation> list = [];
      for (var row in convRows) {
        final cid = row['id'] as String;
        final otherProfile = convMapOther[cid];

        final lastMsgRows = await _client
            .from('messages')
            .select()
            .eq('conversation_id', cid)
            .order('created_at', ascending: false)
            .limit(1);

        Message? lastMsg;
        if ((lastMsgRows as List).isNotEmpty) {
          lastMsg = Message.fromJson(lastMsgRows.first);
        }

        list.add(Conversation(
          id: cid,
          createdBy: row['created_by'] as String,
          disappearAfterSeconds: row['disappear_after_seconds'] as int? ?? 0,
          lastMessageAt: DateTime.parse(row['last_message_at'] as String),
          other: otherProfile,
          lastMessage: lastMsg,
        ));
      }

      conversations = list;
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> startDirectConversation(String otherUserId) async {
    final res = await _client.rpc('get_or_create_direct_conversation', params: {
      '_other_user_id': otherUserId,
    });
    await loadConversations();
    return res as String;
  }

  Future<List<Profile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await _client.rpc('find_people', params: {
      '_term': query.trim().toLowerCase(),
    });
    final myId = _client.auth.currentUser?.id;
    return (res as List)
        .where((u) => u['id'] != myId)
        .map((u) => Profile.fromJson(u))
        .toList();
  }

  Future<void> sendTextMessage(String conversationId, String text) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null || text.trim().isEmpty) return;

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': myId,
      'body': text.trim(),
      'kind': 'text',
    });

    await _client.from('conversations').update({
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  Future<void> sendMediaMessage({
    required String conversationId,
    required File file,
    required String kind,
    String? mimeType,
    int? durationSeconds,
  }) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;

    final fileExt = file.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExt';
    final storagePath = '$conversationId/$fileName';

    await _client.storage.from('chat-media').upload(storagePath, file);
    final size = await file.length();

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': myId,
      'body': '',
      'kind': kind,
      'media_path': storagePath,
      'media_mime': mimeType ?? 'application/octet-stream',
      'media_name': file.path.split('/').last,
      'media_size': size,
      'media_duration': durationSeconds,
    });

    await _client.from('conversations').update({
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  Future<String> getMediaSignedUrl(String path) async {
    final res = await _client.storage.from('chat-media').createSignedUrl(path, 3600);
    return res;
  }
}
