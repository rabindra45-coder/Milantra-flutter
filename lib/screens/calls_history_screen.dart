import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/call_log.dart';
import '../services/supabase_service.dart';

class CallsHistoryScreen extends StatefulWidget {
  const CallsHistoryScreen({super.key});

  @override
  State<CallsHistoryScreen> createState() => _CallsHistoryScreenState();
}

class _CallsHistoryScreenState extends State<CallsHistoryScreen> {
  List<CallLog> _calls = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCallHistory();
  }

  Future<void> _fetchCallHistory() async {
    final myId = SupabaseService.client.auth.currentUser?.id;
    if (myId == null) return;

    try {
      final res = await SupabaseService.client
          .from('calls')
          .select('id, conversation_id, caller_id, callee_id, kind, status, started_at, answered_at, ended_at, duration_seconds')
          .or('caller_id.eq.$myId,callee_id.eq.$myId')
          .order('started_at', ascending: false)
          .limit(100);

      final list = (res as List).map((r) {
        final outgoing = r['caller_id'] == myId;
        return CallLog(
          id: r['id'] as String,
          conversationId: r['conversation_id'] as String,
          kind: r['kind'] as String,
          status: r['status'] as String,
          outgoing: outgoing,
          startedAt: DateTime.parse(r['started_at'] as String),
          durationSeconds: r['duration_seconds'] as int? ?? 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _calls = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_calls.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.phoneMissed, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No call history', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _calls.length,
      itemBuilder: (ctx, i) {
        final c = _calls[i];
        final isMissed = c.status == 'missed';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isMissed ? Colors.red.withOpacity(0.15) : AppColors.brandPrimary.withOpacity(0.15),
            child: Icon(
              c.kind == 'video' ? LucideIcons.video : LucideIcons.phone,
              color: isMissed ? Colors.red : AppColors.brandPrimary,
              size: 20,
            ),
          ),
          title: Text(
            c.outgoing ? 'Outgoing Call' : 'Incoming Call',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isMissed ? Colors.red : null,
            ),
          ),
          subtitle: Text(
            '${c.outgoing ? "Outgoing" : "Incoming"} • ${DateFormat("MMM d, HH:mm").format(c.startedAt)}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            c.durationSeconds > 0 ? '${c.durationSeconds}s' : c.status,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );
      },
    );
  }
}
