import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../services/app_lock_service.dart';
import '../services/supabase_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lockService = context.watch<AppLockService>();
    final supabaseService = context.watch<SupabaseService>();
    final profile = supabaseService.myProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Security & Privacy', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('PIN App Lock'),
            subtitle: Text(lockService.isPinConfigured ? 'App is protected with PIN' : 'Disabled'),
            value: lockService.isPinConfigured,
            onChanged: (val) {
              if (val) {
                _showSetPinDialog(context);
              } else {
                lockService.removePin();
              }
            },
          ),
          SwitchListTile(
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Use Fingerprint or Face ID to unlock'),
            value: lockService.isBiometricEnabled,
            onChanged: (val) => lockService.setBiometrics(val),
          ),
          const Divider(height: 32),
          const Text('Notifications & Audio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Sound Effects'),
            value: profile?.soundEnabled ?? true,
            onChanged: (val) {
              supabaseService.updateSoundPrefs(
                ringtoneIncoming: profile?.ringtoneIncoming ?? 'classic',
                ringtoneOutgoing: profile?.ringtoneOutgoing ?? 'soft',
                soundEnabled: val,
                vibrateEnabled: profile?.vibrateEnabled ?? true,
              );
            },
          ),
          SwitchListTile(
            title: const Text('Vibrate on Alerts'),
            value: profile?.vibrateEnabled ?? true,
            onChanged: (val) {
              supabaseService.updateSoundPrefs(
                ringtoneIncoming: profile?.ringtoneIncoming ?? 'classic',
                ringtoneOutgoing: profile?.ringtoneOutgoing ?? 'soft',
                soundEnabled: profile?.soundEnabled ?? true,
                vibrateEnabled: val,
              );
            },
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await SupabaseService.client.auth.signOut();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showSetPinDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set 4-Digit PIN'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter 4 digits'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.length == 4) {
                context.read<AppLockService>().setPin(ctrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }
}
