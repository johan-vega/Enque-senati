import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/bootstrap.dart';
import 'core/errors.dart';
import 'core/preferences.dart';
import 'core/reminders.dart';
import 'core/theme.dart';
import 'data/task_repository.dart';
import 'features/auth/session_gate.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/calendar_screen.dart';
import 'features/dashboard/stats_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/tasks/task_controller.dart';
import 'features/tasks/task_editor.dart';
import 'features/tasks/tasks_screen.dart';

class EnfoqueApp extends StatelessWidget {
  const EnfoqueApp({
    super.key,
    required this.preferences,
    required this.configured,
    this.startupError,
  });
  final Preferences preferences;
  final bool configured;
  final String? startupError;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    child: configured
        ? SessionGate(
            auth: FirebaseAuth.instance,
            signedInBuilder: (user) => Workspace(
              key: ValueKey(user.uid),
              user: user,
              preferences: preferences,
            ),
          )
        : SetupScreen(error: startupError),
    builder: (context, home) => MaterialApp(
      title: 'Enfoque',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildTheme(false, preferences.accent),
      darkTheme: buildTheme(true, preferences.accent),
      themeMode: preferences.dark ? ThemeMode.dark : ThemeMode.light,
      home: home,
    ),
  );
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key, this.error});
  final String? error;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(28),
            children: [
              Text(
                'enfoque',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 28),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/escritorio.jpg',
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Conecta tu espacio.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                error ?? 'Falta la configuración de Firebase. Sigue la guía incluida en el proyecto para conectar tu cuenta y sincronizar tus tareas.',
              ),
              const SizedBox(height: 16),
              const SelectableText(
                'Guía: docs/CONFIGURACION_FIREBASE.md\n\nPara usar los emuladores locales:\nflutter run --dart-define=USE_EMULATORS=true',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class Workspace extends StatefulWidget {
  const Workspace({super.key, required this.user, required this.preferences});
  final User user;
  final Preferences preferences;
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> with WidgetsBindingObserver {
  late final FirestoreTaskRepository _repository;
  late final TaskController _controller;
  int _index = 0;
  String? _initializationError;
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repository = FirestoreTaskRepository(
      FirebaseFirestore.instance,
      widget.user.uid,
    );
    _controller = TaskController(_repository, LocalReminders())..start();
    widget.preferences.addListener(_preferencesChanged);
    _preferencesChanged();
    unawaited(
      widget.preferences.bind(FirebaseFirestore.instance, widget.user.uid),
    );
    _initialize();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _controller.refreshReminders();
        setState(() {});
      }
    });
  }

  Future<void> _initialize() async {
    try {
      await _repository.ensureDefaults();
      if (mounted) setState(() => _initializationError = null);
    } catch (e) {
      if (mounted) setState(() => _initializationError = readableError(e));
    }
  }

  void _preferencesChanged() =>
      _controller.setNotifications(widget.preferences.notifications);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.refreshReminders();
      setState(() {});
    }
  }

  Future<void> _signOut() async {
    await _controller.close();
    await widget.preferences.bind(FirebaseFirestore.instance, null);
    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.preferences.removeListener(_preferencesChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final status = _controller.loading
          ? 'Conectando con tus tareas…'
          : _controller.pending
          ? 'Cambios por sincronizar'
          : _controller.fromCache
          ? 'Datos en caché · conexión sin confirmar'
          : 'Sincronizado';
      final issue =
          _controller.error ??
          _initializationError ??
          _controller.reminderError;
      final screens = [
        DashboardScreen(
          controller: _controller,
          name: widget.user.displayName ?? '',
        ),
        TasksScreen(controller: _controller),
        CalendarScreen(controller: _controller),
        StatsScreen(controller: _controller),
        SettingsScreen(
          preferences: widget.preferences,
          controller: _controller,
          user: widget.user,
          onSignOut: _signOut,
        ),
      ];
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'enfoque',
            style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -.8),
          ),
          actions: [
            if (useEmulators)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Text('EMULADOR', style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Row(
                    children: [
                      Icon(
                        _controller.pending || _controller.fromCache
                            ? Icons.cloud_queue
                            : Icons.cloud_done_outlined,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          status,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                if (issue != null)
                  MaterialBanner(
                    content: Text(issue),
                    actions: [
                      TextButton(
                        onPressed: () {
                          _controller.retry();
                          _initialize();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                if (_controller.loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: IndexedStack(index: _index, children: screens),
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: _index < 3
            ? FloatingActionButton.extended(
                onPressed: () => openTaskEditor(context, _controller),
                icon: const Icon(Icons.add),
                label: const Text('Nueva tarea'),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (v) => setState(() => _index = v),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              label: 'Tareas',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Calendario',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              label: 'Avance',
            ),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Ajustes'),
          ],
        ),
      );
    },
  );
}
