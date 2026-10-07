import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for District Car applications
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return customerAndroid;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDwi6OV-l7mDqCpPaRI4Yn9gUXiZrf73QM',
    appId: '1:319163006406:web:c4807f606480e920fa46c7',
    messagingSenderId: '319163006406',
    projectId: 'districtcar-4b880',
    authDomain: 'districtcar-4b880.firebaseapp.com',
    storageBucket: 'districtcar-4b880.firebasestorage.app',
  );

  /// Official Android configuration for Customer App (com.districtcarcustomerd.app)
  static const FirebaseOptions customerAndroid = FirebaseOptions(
    apiKey: 'AIzaSyDwi6OV-l7mDqCpPaRI4Yn9gUXiZrf73QM',
    appId: '1:319163006406:android:79e09e87d733ac7afa46c7',
    messagingSenderId: '319163006406',
    projectId: 'districtcar-4b880',
    storageBucket: 'districtcar-4b880.firebasestorage.app',
  );

  /// Official Android configuration for Driver App (com.drivercardistrict.app)
  static const FirebaseOptions driverAndroid = FirebaseOptions(
    apiKey: 'AIzaSyDwi6OV-l7mDqCpPaRI4Yn9gUXiZrf73QM',
    appId: '1:319163006406:android:c4807f606480e920fa46c7',
    messagingSenderId: '319163006406',
    projectId: 'districtcar-4b880',
    storageBucket: 'districtcar-4b880.firebasestorage.app',
  );

  /// Backward compatibility alias
  static const FirebaseOptions android = customerAndroid;

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwi6OV-l7mDqCpPaRI4Yn9gUXiZrf73QM',
    appId: '1:319163006406:ios:c4807f606480e920fa46c7',
    messagingSenderId: '319163006406',
    projectId: 'districtcar-4b880',
    storageBucket: 'districtcar-4b880.firebasestorage.app',
  );
}
