import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.auth,
    required this.signedInBuilder,
  });

  final FirebaseAuth auth;
  final Widget Function(User user) signedInBuilder;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Stream<User?> _session;

  @override
  void initState() {
    super.initState();
    _session = widget.auth.authStateChanges();
  }

  @override
  void didUpdateWidget(covariant SessionGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.auth, widget.auth)) {
      _session = widget.auth.authStateChanges();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: _session,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return const Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No se pudo recuperar la sesión. Reinicia la aplicación.',
                ),
              ),
            ),
          ),
        );
      }
      final user = snapshot.data;
      return user == null
          ? AuthScreen(auth: widget.auth)
          : widget.signedInBuilder(user);
    },
  );
}
