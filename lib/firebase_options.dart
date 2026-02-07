// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCm4Y_wdSLApTxwHncW4Ate30B1ZtfZztU',
    appId: '1:591423985812:web:cfb1e89bbe6afc9c41bc81',
    messagingSenderId: '591423985812',
    projectId: 'hyperspace-flutter-nw',
    authDomain: 'hyperspace-flutter-nw.firebaseapp.com',
    storageBucket: 'hyperspace-flutter-nw.firebasestorage.app',
    measurementId: 'G-P28M5XMKKV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCm4Y_wdSLApTxwHncW4Ate30B1ZtfZztU',
    appId: '1:591423985812:web:cfb1e89bbe6afc9c41bc81',
    messagingSenderId: '591423985812',
    projectId: 'hyperspace-flutter-nw',
    storageBucket: 'hyperspace-flutter-nw.firebasestorage.app',
  );
}
