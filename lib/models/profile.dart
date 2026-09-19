class Profile {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? countryCode;
  final String? country;
  final String ringtoneIncoming;
  final String ringtoneOutgoing;
  final bool soundEnabled;
  final bool vibrateEnabled;
  final DateTime lastSeen;

  Profile({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.phone,
    this.countryCode,
    this.country,
    this.ringtoneIncoming = 'classic',
    this.ringtoneOutgoing = 'soft',
    this.soundEnabled = true,
    this.vibrateEnabled = true,
    required this.lastSeen,
  });

  String get initials {
    final name = displayName ?? username ?? '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      phone: json['phone'] as String?,
      countryCode: json['country_code'] as String?,
      country: json['country'] as String?,
      ringtoneIncoming: json['ringtone_incoming'] as String? ?? 'classic',
      ringtoneOutgoing: json['ringtone_outgoing'] as String? ?? 'soft',
      soundEnabled: json['sound_enabled'] as bool? ?? true,
      vibrateEnabled: json['vibrate_enabled'] as bool? ?? true,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'phone': phone,
      'country_code': countryCode,
      'country': country,
      'ringtone_incoming': ringtoneIncoming,
      'ringtone_outgoing': ringtoneOutgoing,
      'sound_enabled': soundEnabled,
      'vibrate_enabled': vibrateEnabled,
      'last_seen': lastSeen.toIso8601String(),
    };
  }
}
