import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const init = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(init);
    tz.initializeTimeZones();
    _initialized = true;
  }

  Future<void> scheduleNoteReminder({
    required int noteId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await initialize();
    final tzTime = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      noteId,
      title,
      body,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails('note_reminders', 'Note Reminders', importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> cancelReminder(int noteId) async {
    await initialize();
    await _plugin.cancel(noteId);
  }
}


