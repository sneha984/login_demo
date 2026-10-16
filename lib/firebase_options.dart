import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web platform not configured for this demo.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAsUNZT-1NvaWunAdUGScz0beQnJ9p3yKo',
    appId: '1:254089364218:android:5766b4179df8faef64bf43',
    messagingSenderId: '254089364218',
    projectId: 'logindemo-fb6d0',
    storageBucket: 'logindemo-fb6d0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC-4Fc_1ZSCAV_UYstorp4hvhJ_Us_ZGXM',
    appId: '1:254089364218:ios:b8a3aae0e5362ec964bf43',
    messagingSenderId: '254089364218',
    projectId: 'logindemo-fb6d0',
    storageBucket: 'logindemo-fb6d0.firebasestorage.app',
    iosClientId:
        '254089364218-slal1p6njcad7gvga8di2ltsedqe9idb.apps.googleusercontent.com',
    iosBundleId: 'com.example.loginDemo',
  );
}
