import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../services/supabase_service.dart';
import '../widgets/avatar_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<SupabaseService>().myProfile;
    if (p != null) {
      _nameCtrl.text = p.displayName ?? '';
      _usernameCtrl.text = p.username ?? '';
      _bioCtrl.text = p.bio ?? '';
      _phoneCtrl.text = p.phone ?? '';
    }
  }

  void _save() async {
    setState(() => _saving = true);
    try {
      await context.read<SupabaseService>().updateProfile(
            displayName: _nameCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pickAvatar() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null && mounted) {
      final myId = context.read<SupabaseService>().currentUserId;
      final file = File(img.path);
      final path = '$myId/avatar.jpg';
      await SupabaseService.client.storage.from(AppConstants.avatarsBucket).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl = SupabaseService.client.storage.from(AppConstants.avatarsBucket).getPublicUrl(path);
      await SupabaseService.client.from('profiles').update({'avatar_url': publicUrl}).eq('id', myId!);
      context.read<SupabaseService>().fetchMyProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SupabaseService>().myProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                AvatarWidget(url: profile?.avatarUrl, name: profile?.displayName, size: 96),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandPrimary,
                    ),
                    child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(LucideIcons.user)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(LucideIcons.atSign)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(LucideIcons.phone)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(LucideIcons.fileText)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _saving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
