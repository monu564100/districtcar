import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'core/router.dart';

import 'package:district_car_shared/firebase_options.dart';

import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: kIsWeb ? DefaultFirebaseOptions.web : DefaultFirebaseOptions.driverAndroid,
    );
  } catch (e) {
    debugPrint('Firebase driver app init notice: $e');
  }
  runApp(const ProviderScope(child: DistrictCarDriverApp()));
}

class DistrictCarDriverApp extends ConsumerWidget {
  const DistrictCarDriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(driverRouterProvider);

    return MaterialApp.router(
      title: 'District Car Partner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
