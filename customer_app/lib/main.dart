import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:district_car_shared/theme/app_theme.dart';
import 'core/router.dart';

import 'package:district_car_shared/firebase_options.dart';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:district_car_shared/services/fcm_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: kIsWeb ? DefaultFirebaseOptions.web : DefaultFirebaseOptions.customerAndroid,
    );
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }
  runApp(const ProviderScope(child: DistrictCarCustomerApp()));
}

class DistrictCarCustomerApp extends ConsumerWidget {
  const DistrictCarCustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'District Car',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
