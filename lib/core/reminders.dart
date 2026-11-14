import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/task.dart';

tz.Location deviceLocation(String identifier) {
  // Android can report GMT, while the compact timezone database omits aliases.
  if (const {'GMT', 'UTC', 'Etc/GMT', 'Etc/UTC'}.contains(identifier)) {
    return tz.UTC;
  }
  return tz.getLocation(identifier);
}

List<Task> reminderPlan(Iterable<Task> tasks, DateTime now, bool enabled) {
  if (!enabled) return [];
  final future =
      tasks
          .where(
            (t) =>
                t.reminder &&
                !t.completed &&
                t.dueAt != null &&
                t.dueAt!.isAfter(now),
          )
          .toList()
        ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
  // Leave room below Apple's 64 pending requests limit.
  return future.take(60).toList();
}

abstract interface class ReminderService {
  bool get supported;
  Future<bool> requestPermission();
  Future<void> reconcile(List<Task> tasks, bool enabled);
  Future<void> clear();
}

class LocalReminders implements ReminderService {
  final plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String _signature = '';
  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<void> _initialize() async {
    if (_initialized || !supported) return;
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(deviceLocation(zone.identifier));
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!supported) return false;
    await _initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  @override
  Future<void> reconcile(List<Task> tasks, bool enabled) async {
    if (!supported) return;
    await _initialize();
    final plan = reminderPlan(tasks, DateTime.now(), enabled);
    final signature = plan
        .map((t) => '${t.id}|${t.title}|${t.dueAt!.toUtc().toIso8601String()}')
        .join(';');
    if (signature == _signature && _signature.isNotEmpty) return;
    await plugin.cancelAll();
    for (var i = 0; i < plan.length; i++) {
      final task = plan[i];
      await plugin.zonedSchedule(
        id: i + 1,
        title: task.title,
        body: 'Es hora de tu tarea.',
        scheduledDate: tz.TZDateTime.from(task.dueAt!, tz.local),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'enfoque_tasks',
            'Recordatorios de tareas',
            channelDescription: 'Avisos para las tareas que programas',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: task.id,
      );
    }
    _signature = signature;
  }

  @override
  Future<void> clear() async {
    if (!supported) return;
    await _initialize();
    await plugin.cancelAll();
    _signature = '';
  }
}
