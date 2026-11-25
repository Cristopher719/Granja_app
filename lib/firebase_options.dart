// ignore_for_file: type=lint
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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyD-sZ_9mBoJnU_EJ3qWKRzLTQfc-7ygTBQ',
    appId: '1:313631680247:web:e49d6ff152dbbadf4115f2',
    messagingSenderId: '313631680247',
    projectId: 'granja-app-1046e',
    authDomain: 'granja-app-1046e.firebaseapp.com',
    storageBucket: 'granja-app-1046e.firebasestorage.app',
    measurementId: 'G-V5G37171VJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAuhDzXR7f8uZH2AkFGoOHijV2VGgws0O4',
    appId: '1:313631680247:android:d82f33f8d58fcb574115f2',
    messagingSenderId: '313631680247',
    projectId: 'granja-app-1046e',
    storageBucket: 'granja-app-1046e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCvP7PwHFDb1ucnjXYLYygmu_5nfSJ4LTw',
    appId: '1:313631680247:ios:2c9a13c4e22323804115f2',
    messagingSenderId: '313631680247',
    projectId: 'granja-app-1046e',
    storageBucket: 'granja-app-1046e.firebasestorage.app',
    iosBundleId: 'com.example.appGranja',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCvP7PwHFDb1ucnjXYLYygmu_5nfSJ4LTw',
    appId: '1:313631680247:ios:2c9a13c4e22323804115f2',
    messagingSenderId: '313631680247',
    projectId: 'granja-app-1046e',
    storageBucket: 'granja-app-1046e.firebasestorage.app',
    iosBundleId: 'com.example.appGranja',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD-sZ_9mBoJnU_EJ3qWKRzLTQfc-7ygTBQ',
    appId: '1:313631680247:web:9c3c5cc4230bd3574115f2',
    messagingSenderId: '313631680247',
    projectId: 'granja-app-1046e',
    authDomain: 'granja-app-1046e.firebaseapp.com',
    storageBucket: 'granja-app-1046e.firebasestorage.app',
    measurementId: 'G-QXTNYLNPGB',
  );
}
