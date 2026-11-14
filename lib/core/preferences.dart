import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences extends ChangeNotifier {
  Preferences(this.storage) {
    dark = storage.getBool('dark') ?? false;
    accent = (storage.getInt('accent') ?? 0).clamp(0, 2);
    notifications = storage.getBool('notifications') ?? false;
  }
  final SharedPreferences storage;
  bool dark = false, notifications = false;
  int accent = 0;
  String? syncError;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  DocumentReference<Map<String, dynamic>>? _remote;
  Future<void> bind(FirebaseFirestore db, String? uid) async {
    await _subscription?.cancel();
    _remote = uid == null
        ? null
        : db
              .collection('users')
              .doc(uid)
              .collection('preferences')
              .doc('interface');
    _subscription = _remote?.snapshots().listen(
      (snapshot) {
        final d = snapshot.data();
        if (d == null) return;
        final nextDark = d['dark'] == true;
        final nextAccent = (d['accent'] as int? ?? 0).clamp(0, 2);
        final nextNotifications = d['notifications'] == true;
        if (dark == nextDark &&
            accent == nextAccent &&
            notifications == nextNotifications) {
          return;
        }
        dark = nextDark;
        accent = nextAccent;
        notifications = nextNotifications;
        unawaited(_persist());
        notifyListeners();
      },
      onError: (Object e) {
        syncError = 'No se pudieron sincronizar las preferencias.';
        notifyListeners();
      },
    );
  }

  Future<void> update({bool? dark, int? accent, bool? notifications}) async {
    final nextDark = dark ?? this.dark;
    final nextAccent = (accent ?? this.accent).clamp(0, 2);
    final nextNotifications = notifications ?? this.notifications;
    if (this.dark == nextDark &&
        this.accent == nextAccent &&
        this.notifications == nextNotifications) {
      return;
    }
    this.dark = nextDark;
    this.accent = nextAccent;
    this.notifications = nextNotifications;
    syncError = null;
    notifyListeners();
    await _persist();
    try {
      await _remote?.set({
        'dark': this.dark,
        'accent': this.accent,
        'notifications': this.notifications,
      });
    } catch (_) {
      syncError = 'Preferencias guardadas en este dispositivo; sincronización pendiente.';
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    await storage.setBool('dark', dark);
    await storage.setInt('accent', accent);
    await storage.setBool('notifications', notifications);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
