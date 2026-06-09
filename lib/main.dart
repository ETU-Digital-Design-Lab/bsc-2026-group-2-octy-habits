import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_router.dart';
import 'core/notifications/local_notifications_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Intl.defaultLocale = 'tr_TR';
  await initializeDateFormatting('tr_TR');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationsService.instance.initialize();

  runApp(const ProviderScope(child: OctyApp()));
}

class OctyApp extends ConsumerWidget {
  const OctyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final profile = user == null
        ? null
        : ref.watch(userProfileProvider(user.uid)).valueOrNull;
    final themeMode = switch (profile?['themeMode']) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

    return MaterialApp.router(
      title: 'Octy Alışkanlıklar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
