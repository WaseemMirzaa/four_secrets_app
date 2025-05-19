import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'No Web options have been provided yet - configure Firebase for Web',
      );
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

 static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDy1sDKpTOFoNcqHowgdCHxl_wV9l8CEi4',
    appId: '1:969854232661:ios:8546a9466d700ae70e0cdc',
    messagingSenderId: '969854232661',
    projectId: 'secrets-wedding',
    storageBucket: 'secrets-wedding.firebasestorage.app',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDyrLax7e8fYhRnvuqLya259xbGMfNAdpA',
    appId: '1:969854232661:android:c16da12a98b0e3f60e0cdc',
    messagingSenderId: '969854232661',
    projectId: 'secrets-wedding',
    storageBucket: 'secrets-wedding.firebasestorage.app',
  );
}
