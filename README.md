# Milantra Flutter App (Converted from Milantra Web App)

Milantra is a private, secure, and modern communication platform featuring real-time messaging, WebRTC audio/video calling, voice notes, media sharing, and biometric/PIN app lock.

## Features Included in Flutter
- **Authentication**: Email/password authentication via Supabase Auth.
- **Conversations & Real-Time Messaging**: Real-time Postgres subscriptions for instant text and media delivery.
- **WebRTC Voice & Video Calls**: Peer-to-peer audio & video streaming with camera switching, mute, and speaker controls.
- **Voice Notes**: In-app microphone audio recording with duration counter and instant upload.
- **Media & Photos**: Image capture & picker with secure upload to Supabase Storage buckets.
- **Security & Privacy**: PIN code protection and native biometric authentication (Fingerprint / Face ID).
- **Call History**: Outgoing/incoming and missed call tracking.
- **Profile & Sound Preferences**: Customizable display name, bio, ringtones, vibration, and sound alerts.

## Getting Started in Android Studio

1. **Prerequisites**:
   - Flutter SDK (>= 3.19.0)
   - Android Studio with Flutter and Dart plugins installed
   - Android SDK (API 21+)

2. **Open the Project**:
   - Open Android Studio.
   - Click **Open** and select the unzipped `milantra_app` folder.

3. **Get Dependencies**:
   - Run `flutter pub get` in the terminal or click **Pub get** in Android Studio.

4. **Configure Supabase Credentials**:
   - Open `lib/core/constants.dart`.
   - Replace `supabaseUrl` and `supabaseAnonKey` with your Supabase project credentials.

5. **Run the App**:
   - Select an Android emulator or connected device.
   - Click **Run** (or press `Shift + F10`).
