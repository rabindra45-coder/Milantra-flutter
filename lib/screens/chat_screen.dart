import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../services/chat_service.dart';
import '../services/supabase_service.dart';
import '../services/webrtc_call_service.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_recorder_bar.dart';
import 'call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Profile? peer;

  const ChatScreen({super.key, required this.conversationId, this.peer});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  List<Message> _messages = [];
  bool _recording = false;
  RealtimeChannel? _sub;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeMessages();
  }

  Future<void> _loadMessages() async {
    final res = await SupabaseService.client
        .from('messages')
        .select()
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true);

    if (mounted) {
      setState(() {
        _messages = (res as List).map((m) => Message.fromJson(m)).toList();
      });
      _scrollToBottom();
    }
  }

  void _subscribeMessages() {
    _sub = SupabaseService.client.channel('messages:${widget.conversationId}')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: widget.conversationId,
        ),
        callback: (payload) {
          final newMsg = Message.fromJson(payload.newRecord);
          if (mounted) {
            setState(() {
              _messages.add(newMsg);
            });
            _scrollToBottom();
          }
        },
      ).subscribe();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendText() async {
    final text = _textCtrl.text;
    if (text.trim().isEmpty) return;
    _textCtrl.clear();
    await context.read<ChatService>().sendTextMessage(widget.conversationId, text);
  }

  void _pickAndSendImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null && mounted) {
      await context.read<ChatService>().sendMediaMessage(
            conversationId: widget.conversationId,
            file: File(img.path),
            kind: 'image',
            mimeType: 'image/jpeg',
          );
    }
  }

  void _startCall(bool video) {
    if (widget.peer == null) return;
    context.read<WebRTCCallService>().startCall(
          conversationId: widget.conversationId,
          targetUser: widget.peer!,
          video: video,
        );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(peer: widget.peer!, isVideo: video),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.unsubscribe();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<SupabaseService>().currentUserId ?? '';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarWidget(url: widget.peer?.avatarUrl, name: widget.peer?.displayName ?? widget.peer?.username),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peer?.displayName ?? widget.peer?.username ?? 'Chat',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Text('Online', style: TextStyle(fontSize: 12, color: AppColors.brandPrimary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.phone),
            onPressed: () => _startCall(false),
          ),
          IconButton(
            icon: const Icon(LucideIcons.video),
            onPressed: () => _startCall(true),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                return MessageBubble(
                  message: msg,
                  isMe: msg.isFromMe(myId),
                  onCallbackCall: () => _startCall(false),
                );
              },
            ),
          ),
          if (_recording)
            VoiceRecorderBar(
              onCancel: () => setState(() => _recording = false),
              onRecorded: (file, seconds) async {
                setState(() => _recording = false);
                await context.read<ChatService>().sendMediaMessage(
                      conversationId: widget.conversationId,
                      file: file,
                      kind: 'voice',
                      mimeType: 'audio/m4a',
                      durationSeconds: seconds,
                    );
              },
            )
          else
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.plusCircle),
                      onPressed: _pickAndSendImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        maxLines: 4,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.mic),
                      onPressed: () => setState(() => _recording = true),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.send, color: AppColors.brandPrimary),
                      onPressed: _sendText,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
