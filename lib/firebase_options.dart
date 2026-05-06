import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return environment == 'stg' ? stgWeb : devWeb;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return environment == 'stg' ? stgAndroid : devAndroid;
      case TargetPlatform.iOS:
        return environment == 'stg' ? stgIOS : devIOS;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions devWeb = FirebaseOptions(
    apiKey: 'AIzaSyADevBYu1QSm1wAmGKfqD3puNR9vyLB9-Y',
    appId: '1:746144014024:web:277d6ef1135278519d0ffd',
    messagingSenderId: '746144014024',
    projectId: 'stanblackjack-dev',
    authDomain: 'stanblackjack-dev.firebaseapp.com',
    storageBucket: 'stanblackjack-dev.firebasestorage.app',
  );

  static const FirebaseOptions stgWeb = FirebaseOptions(
    apiKey: 'AIzaSyCs6NwioVHNT8S47zy6YkTQBVA4v1f06GU',
    appId: '1:230746278474:web:349ebf5533f4c1f38af4b3',
    messagingSenderId: '230746278474',
    projectId: 'stanblackjack-stg',
    authDomain: 'stanblackjack-stg.firebaseapp.com',
    storageBucket: 'stanblackjack-stg.firebasestorage.app',
  );

  // Placeholders for Android/iOS if needed later
  static const FirebaseOptions devAndroid = devWeb; // Just as placeholders
  static const FirebaseOptions devIOS = devWeb;
  static const FirebaseOptions stgAndroid = stgWeb;
  static const FirebaseOptions stgIOS = stgWeb;
}
