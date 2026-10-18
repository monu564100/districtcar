import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'core/router.dart';

import 'package:district_car_shared/firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('>>> ADMIN PANEL MAIN STARTED <<<');

  runApp(const ProviderScope(child: DistrictCarAdminPanelApp()));

  Future.microtask(() async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('>>> INITIALIZING FIREBASE WEB <<<');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 4));
        debugPrint('>>> FIREBASE WEB INITIALIZED SUCCESSFULLY <<<');
      }
    } catch (e) {
      debugPrint('>>> FIREBASE INIT NOTICE: $e <<<');
    }
  });
}

class DistrictCarAdminPanelApp extends ConsumerWidget {
  const DistrictCarAdminPanelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('>>> BUILDING DistrictCarAdminPanelApp <<<');
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'District Car — Operations & Admin Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
