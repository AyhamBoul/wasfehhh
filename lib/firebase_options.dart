import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDrD1fLuvLjeXZEhEgLF6DUhbhrfXB_UFc',
    appId: '1:991034476196:web:854435c8b783ca16df0831',
    messagingSenderId: '991034476196',
    projectId: 'wasfeh-f9b26',
    authDomain: 'wasfeh-f9b26.firebaseapp.com',
    storageBucket: 'wasfeh-f9b26.firebasestorage.app',
    measurementId: 'G-SXW3QSLWKZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBrTyf7gJFyZX8XBMh01ZUkHbpnQND58Wo',
    appId: '1:991034476196:android:1ba5e973ec457d98df0831',
    messagingSenderId: '991034476196',
    projectId: 'wasfeh-f9b26',
    storageBucket: 'wasfeh-f9b26.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB24ksJgo34t_V8Hz9-s5FvaMkI-LI3dkM',
    appId: '1:991034476196:ios:ee8b04ca04f95a09df0831',
    messagingSenderId: '991034476196',
    projectId: 'wasfeh-f9b26',
    storageBucket: 'wasfeh-f9b26.firebasestorage.app',
    iosBundleId: 'com.example.wasfehhh',
  );
}
