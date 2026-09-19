import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/conversation.dart';
import '../models/profile.dart';
import '../services/chat_service.dart';
import '../services/supabase_service.dart';
import '../widgets/avatar_widget.dart';
import 'chat_screen.dart';
import 'calls_history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseService>().fetchMyProfile();
      context.read<ChatService>().loadConversations();
    });
  }

  void _openNewChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _NewChatSheet(onSelected: (Profile user) async {
        Navigator.pop(ctx);
        final cid = await context.read<ChatService>().startDirectConversation(user.id);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversationId: cid, peer: user),
            ),
          );
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<ChatService>();

    final filtered = chatService.conversations.where((c) {
      final name = '${c.other?.displayName ?? ""} ${c.other?.username ?? ""}'.toLowerCase();
      return name.contains(_filter.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(LucideIcons.shieldCheck, color: AppColors.brandPrimary),
            SizedBox(width: 8),
            Text('Milantra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.messageSquarePlus),
            onPressed: _openNewChatDialog,
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RefreshIndicator(
            onRefresh: () => chatService.loadConversations(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _filter = v),
                    decoration: InputDecoration(
                      hintText: 'Search conversations...',
                      prefixIcon: const Icon(LucideIcons.search, size: 20),
                      suffixIcon: _filter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _filter = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: chatService.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.messagesSquare, size: 48, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  const Text('No conversations yet',
                                      style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _openNewChatDialog,
                                    child: const Text('Start a conversation'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final conv = filtered[i];
                                final lastMsg = conv.lastMessage;
                                return ListTile(
                                  leading: AvatarWidget(
                                    url: conv.other?.avatarUrl,
                                    name: conv.other?.displayName ?? conv.other?.username,
                                    size: 48,
                                  ),
                                  title: Text(
                                    conv.other?.displayName ?? conv.other?.username ?? 'Conversation',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    lastMsg != null
                                        ? (lastMsg.kind == 'voice'
                                            ? '🎤 Voice note'
                                            : lastMsg.kind == 'image'
                                                ? '🖼️ Photo'
                                                : lastMsg.body)
                                        : 'No messages yet',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    DateFormat('HH:mm').format(conv.lastMessageAt),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          conversationId: conv.id,
                                          peer: conv.other,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          const CallsHistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.messageCircle), label: 'Chats'),
          NavigationDestination(icon: Icon(LucideIcons.phone), label: 'Calls'),
          NavigationDestination(icon: Icon(LucideIcons.user), label: 'Profile'),
        ],
      ),
    );
  }
}

class _NewChatSheet extends StatefulWidget {
  final ValueChanged<Profile> onSelected;
  const _NewChatSheet({required this.onSelected});

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final _ctrl = TextEditingController();
  List<Profile> _results = [];
  bool _searching = false;

  void _doSearch(String q) async {
    if (q.trim().length < 2) return;
    setState(() => _searching = true);
    final res = await context.read<ChatService>().searchUsers(q);
    if (mounted) setState(() {
      _results = res;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Start a Conversation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: _doSearch,
            decoration: const InputDecoration(
              hintText: 'Search username or +phone...',
              prefixIcon: Icon(LucideIcons.search),
            ),
          ),
          const SizedBox(height: 16),
          if (_searching) const Center(child: CircularProgressIndicator()),
          if (!_searching && _results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final u = _results[i];
                  return ListTile(
                    leading: AvatarWidget(url: u.avatarUrl, name: u.displayName ?? u.username),
                    title: Text(u.displayName ?? u.username ?? ''),
                    subtitle: Text('@${u.username ?? ""}'),
                    onTap: () => widget.onSelected(u),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
