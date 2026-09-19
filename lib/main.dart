import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/app_lock_service.dart';
import 'services/chat_service.dart';
import 'services/supabase_service.dart';
import 'services/webrtc_call_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  final appLockService = AppLockService();
  await appLockService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SupabaseService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => WebRTCCallService()),
        ChangeNotifierProvider.value(value: appLockService),
      ],
      child: const MilantraApp(),
    ),
  );
}

class MilantraApp extends StatelessWidget {
  const MilantraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milantra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
          if (session == null) {
            return const AuthScreen();
          }
          return const HomeScreen();
        },
      ),
    );
  }
}
