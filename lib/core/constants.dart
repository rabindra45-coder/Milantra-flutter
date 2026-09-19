import 'package:flutter/material.dart';

class AppConstants {
  // Replace these with your Supabase credentials
  static const String supabaseUrl = 'https://YOUR_SUPABASE_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static const String chatMediaBucket = 'chat-media';
  static const String avatarsBucket = 'avatars';

  static const Map<String, dynamic> rtcIceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };
}

class AppColors {
  static const Color brandPrimary = Color(0xFF10B981); // Emerald
  static const Color brandSecondary = Color(0xFF06B6D4); // Cyan
  static const Color brandAccent = Color(0xFF6366F1); // Indigo

  static const LinearGradient brandGradient = LinearGradient(
    colors: [brandPrimary, brandSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkCard = Color(0xFF131B2E);
  static const Color darkSurface = Color(0xFF1E293B);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF1F5F9);
}
