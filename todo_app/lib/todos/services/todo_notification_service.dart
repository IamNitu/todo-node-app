import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/todo_model.dart';

class TodoNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _timeZoneName = String.fromEnvironment(
    'TODO_TIME_ZONE',
    defaultValue: 'Asia/Kathmandu',
  );
  bool _initialized = false;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_timeZoneName));

    if (kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return;
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final notificationsAllowed = await android
          ?.requestNotificationsPermission();
      if (notificationsAllowed == false) return false;

      final exactAllowed = await android?.canScheduleExactNotifications();
      if (exactAllowed != true) {
        await android?.requestExactAlarmsPermission();
      }
      return notificationsAllowed != false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  Future<void> schedule(TodoModel todo) async {
    final id = todo.id;
    final dueAt = todo.dueAt;
    if (!_initialized ||
        id == null ||
        dueAt == null ||
        todo.completed ||
        !todo.reminderEnabled) {
      return;
    }

    final localDueAt = dueAt.toLocal();
    if (!localDueAt.isAfter(DateTime.now())) return;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exactAllowed = await android?.canScheduleExactNotifications() ?? true;
    final notificationId = _notificationId(id);

    await _plugin.zonedSchedule(
      id: notificationId,
      title: 'Todo reminder',
      body: todo.title,
      scheduledDate: tz.TZDateTime.from(localDueAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminders',
          'Todo reminders',
          channelDescription: 'Reminders for scheduled todo tasks',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: id,
    );
  }

  Future<void> cancel(String? id) async {
    if (!_initialized || id == null) return;
    await _plugin.cancel(id: _notificationId(id));
  }

  int _notificationId(String id) {
    final suffix = id.length > 7 ? id.substring(id.length - 7) : id;
    return int.tryParse(suffix, radix: 16) ?? id.hashCode.abs();
  }
}
