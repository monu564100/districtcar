import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'core/router.dart';

import 'package:district_car_shared/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase admin init notice: $e');
  }
  runApp(const ProviderScope(child: DistrictCarAdminPanelApp()));
}

class DistrictCarAdminPanelApp extends ConsumerWidget {
  const DistrictCarAdminPanelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'District Car — Operations & Admin Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
