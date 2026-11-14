import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/bootstrap.dart';
import 'core/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = Preferences(await SharedPreferences.getInstance());
  var configured = false;
  String? error;
  try {
    configured = await initializeFirebase();
  } catch (_) {
    error = 'No pudimos iniciar Firebase. Revisa la configuración y vuelve a abrir la aplicación.';
  }
  runApp(
    EnfoqueApp(
      preferences: preferences,
      configured: configured,
      startupError: error,
    ),
  );
}
