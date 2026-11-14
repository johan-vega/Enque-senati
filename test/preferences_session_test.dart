import 'dart:async';

import 'package:enfoque/core/preferences.dart';
import 'package:enfoque/core/theme.dart';
import 'package:enfoque/features/auth/session_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _User extends Fake implements User {}

class _Auth extends Fake implements FirebaseAuth {
  final events = StreamController<User?>.broadcast();
  final user = _User();
  int requests = 0, subscriptions = 0, cancellations = 0;

  @override
  Stream<User?> authStateChanges() {
    requests++;
    return Stream<User?>.multi((sink) {
      subscriptions++;
      sink.add(user);
      final sub = events.stream.listen(sink.add, onError: sink.addError);
      sink.onCancel = () async {
        cancellations++;
        await sub.cancel();
      };
    });
  }
}

class _WorkspaceProbe extends StatefulWidget {
  const _WorkspaceProbe({required this.onMount});
  final VoidCallback onMount;
  @override
  State<_WorkspaceProbe> createState() => _WorkspaceProbeState();
}

class _WorkspaceProbeState extends State<_WorkspaceProbe> {
  final draft = TextEditingController();
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextField(
      controller: draft,
      decoration: const InputDecoration(labelText: 'Borrador'),
    ),
  );
}

void main() {
  test('actualizaciones idénticas no disparan reconstrucciones', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = Preferences(await SharedPreferences.getInstance());
    var changes = 0;
    prefs.addListener(() => changes++);
    await prefs.update(dark: false, accent: 0, notifications: false);
    expect(changes, 0);
    await prefs.update(dark: true);
    await prefs.update(dark: true);
    expect(changes, 1);
    expect(prefs.storage.getBool('dark'), true);
    prefs.dispose();
  });

  testWidgets(
    'cambiar tema y acento mantiene una sola sesión y conserva el borrador',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = Preferences(await SharedPreferences.getInstance());
      final auth = _Auth();
      var mounts = 0;
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: prefs,
          builder: (context, _) => MaterialApp(
            theme: buildTheme(false, prefs.accent),
            darkTheme: buildTheme(true, prefs.accent),
            themeMode: prefs.dark ? ThemeMode.dark : ThemeMode.light,
            home: SessionGate(
              auth: auth,
              signedInBuilder: (_) => _WorkspaceProbe(onMount: () => mounts++),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Preparar la exposición');
      for (var i = 0; i < 6; i++) {
        final dark = i.isEven;
        await prefs.update(dark: dark, accent: i % 3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        auth.events.add(auth.user);
        await tester.pump();
        expect(
          Theme.of(tester.element(find.byType(TextField))).brightness,
          dark ? Brightness.dark : Brightness.light,
        );
        expect(find.text('Preparar la exposición'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(auth.requests, 1);
        expect(auth.subscriptions, 1);
        expect(auth.cancellations, 0);
        expect(mounts, 1);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      await auth.events.close();
      prefs.dispose();
    },
  );
}
