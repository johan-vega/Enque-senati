import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/preferences.dart';
import '../../core/theme.dart';
import '../tasks/categories_screen.dart';
import '../tasks/task_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.controller,
    required this.user,
    required this.onSignOut,
  });
  final Preferences preferences;
  final TaskController controller;
  final User user;
  final Future<void> Function() onSignOut;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _name = TextEditingController(text: widget.user.displayName);
  bool _busy = false;
  String? _message;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _profile() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _message = 'Escribe tu nombre.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.user.updateDisplayName(_name.text.trim());
      if (mounted) setState(() => _message = 'Perfil guardado');
    } catch (e) {
      if (mounted) setState(() => _message = readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _notifications(bool value) async {
    if (value) {
      try {
        if (!await widget.controller.reminders.requestPermission()) {
          if (mounted) {
            setState(
              () => _message = 'Permiso no concedido. Puedes habilitarlo en los ajustes del dispositivo.',
            );
          }
          return;
        }
      } catch (_) {
        if (mounted) {
          setState(
            () =>
                _message = 'No pudimos solicitar el permiso de notificaciones.',
          );
        }
        return;
      }
    }
    await widget.preferences.update(notifications: value);
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
    children: [
      Text('Configuración', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 28),
      Text('Tu cuenta', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      Text(widget.user.email ?? ''),
      const SizedBox(height: 14),
      TextField(
        controller: _name,
        maxLength: 60,
        decoration: const InputDecoration(labelText: 'Nombre'),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: _busy ? null : _profile,
          child: const Text('Guardar perfil'),
        ),
      ),
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 18),
      Text('A tu manera', style: Theme.of(context).textTheme.titleLarge),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Modo oscuro'),
        value: widget.preferences.dark,
        onChanged: (v) => widget.preferences.update(dark: v),
      ),
      const Text('Color de acento'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: List.generate(
          3,
          (i) => ChoiceChip(
            avatar: CircleAvatar(backgroundColor: accentColors[i], radius: 8),
            label: Text(const ['Bosque', 'Arcilla', 'Pizarra'][i]),
            selected: widget.preferences.accent == i,
            onSelected: (_) => widget.preferences.update(accent: i),
          ),
        ),
      ),
      const SizedBox(height: 18),
      const Divider(),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Notificaciones'),
        subtitle: Text(
          widget.controller.reminders.supported
              ? 'Recordatorios locales en este dispositivo. La hora de entrega puede variar.'
              : 'Disponibles en Android e iOS. En web solo se sincronizan las tareas.',
        ),
        value: widget.preferences.notifications,
        onChanged: widget.controller.reminders.supported
            ? _notifications
            : null,
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Categorías'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => CategoriesScreen(controller: widget.controller),
          ),
        ),
      ),
      if (_message != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(_message!),
        ),
      if (widget.preferences.syncError != null)
        Text(widget.preferences.syncError!),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: _busy
            ? null
            : () async {
                setState(() => _busy = true);
                try {
                  await widget.onSignOut();
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _message = readableError(e);
                      _busy = false;
                    });
                  }
                }
              },
        child: const Text('Cerrar sesión'),
      ),
      const SizedBox(height: 24),
      const Text(
        'Enfoque · Proyecto final SENATI\nVersión 1.0.0',
        textAlign: TextAlign.center,
      ),
    ],
  );
}
