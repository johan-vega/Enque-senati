import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const useEmulators = bool.fromEnvironment('USE_EMULATORS');
const emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: 'localhost',
);

Future<bool> initializeFirebase() async {
  const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
  if (!useEmulators && project.isEmpty) return false;
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: String.fromEnvironment(
        'FIREBASE_API_KEY',
        defaultValue: 'demo-api-key',
      ),
      appId: String.fromEnvironment(
        'FIREBASE_APP_ID',
        defaultValue: '1:123456789:android:enfoque',
      ),
      messagingSenderId: String.fromEnvironment(
        'FIREBASE_SENDER_ID',
        defaultValue: '123456789',
      ),
      projectId: String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: 'demo-enfoque',
      ),
      authDomain: String.fromEnvironment(
        'FIREBASE_AUTH_DOMAIN',
        defaultValue: 'demo-enfoque.firebaseapp.com',
      ),
      iosBundleId: 'pe.senati.enfoque.enfoque',
    ),
  );
  if (useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
  }
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  }
  await FirebaseAuth.instance.setLanguageCode('es');
  return true;
}
