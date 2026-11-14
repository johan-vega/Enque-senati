import 'package:firebase_auth/firebase_auth.dart';

String readableError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'email-already-in-use' => 'Este correo ya tiene una cuenta.',
      'invalid-email' => 'El correo no es válido.',
      'weak-password' => 'Elige una contraseña más segura.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Revisa tu correo y contraseña.',
      'too-many-requests' => 'Demasiados intentos. Espera unos minutos.',
      'network-request-failed' => 'No pudimos conectar. Revisa tu conexión.',
      'operation-not-allowed' =>
        'Activa correo y contraseña en Firebase Authentication.',
      _ => 'No pudimos acceder a tu cuenta. Inténtalo de nuevo.',
    };
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'No tienes acceso. Revisa la sesión y las reglas de Firebase.',
      'unavailable' =>
        'Sin conexión con el servidor. Reintentaremos la sincronización.',
      _ => 'No pudimos guardar los cambios. Inténtalo de nuevo.',
    };
  }
  return 'No pudimos completar la acción. Inténtalo de nuevo.';
}
