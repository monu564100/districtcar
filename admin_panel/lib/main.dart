import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'core/router.dart';
import 'package:district_car_shared/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Custom ErrorWidget builder to avoid red screen on web JS interop edge cases
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('Flutter Web Handled Notice: ${details.exception}');
    return Material(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_sync_outlined, color: Color(0xFF38BDF8), size: 48),
              const SizedBox(height: 16),
              const Text(
                'Syncing with Operations Cloud...',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  };

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully.');
    }
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
