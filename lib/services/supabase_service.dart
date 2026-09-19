import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class SupabaseService extends ChangeNotifier {
  static final SupabaseClient client = Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;
  String? get currentUserId => client.auth.currentUser?.id;

  Profile? _myProfile;
  Profile? get myProfile => _myProfile;

  Future<void> fetchMyProfile() async {
    if (currentUserId == null) return;
    try {
      final res = await client
          .from('profiles')
          .select()
          .eq('id', currentUserId!)
          .maybeSingle();

      if (res != null) {
        _myProfile = Profile.fromJson(res);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? phone,
    String? country,
    String? countryCode,
  }) async {
    if (currentUserId == null) return;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (displayName != null) updates['display_name'] = displayName;
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (phone != null) updates['phone'] = phone;
    if (country != null) updates['country'] = country;
    if (countryCode != null) updates['country_code'] = countryCode;

    await client.from('profiles').update(updates).eq('id', currentUserId!);
    await fetchMyProfile();
  }

  Future<void> updateSoundPrefs({
    required String ringtoneIncoming,
    required String ringtoneOutgoing,
    required bool soundEnabled,
    required bool vibrateEnabled,
  }) async {
    if (currentUserId == null) return;
    await client.from('profiles').update({
      'ringtone_incoming': ringtoneIncoming,
      'ringtone_outgoing': ringtoneOutgoing,
      'sound_enabled': soundEnabled,
      'vibrate_enabled': vibrateEnabled,
    }).eq('id', currentUserId!);
    await fetchMyProfile();
  }
}
