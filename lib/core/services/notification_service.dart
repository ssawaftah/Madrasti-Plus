import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/firebase_config.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/attendance_record.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: FirebaseConfig.firestoreDatabaseId,
            );

  final FirebaseFirestore _firestore;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _localNotificationsInitialized = false;
  static bool _foregroundListenerInitialized = false;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'madrasti_plus_alerts',
    'Madrasti Plus Alerts',
    description: 'تنبيهات Madrasti Plus أثناء استخدام التطبيق',
    importance: Importance.high,
  );

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  CollectionReference<Map<String, dynamic>> get _notificationsCollection {
    return _firestore.collection('notifications');
  }

  Future<void> initializeForCurrentUser(String userId) async {
    try {
      await _initializeLocalNotifications();
      _initializeForegroundMessageListener();

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();

      if (token == null || token.isEmpty) return;

      await _usersCollection.doc(userId).set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lastFcmTokenUpdatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to initialize notifications: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    const androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );

    await _localNotifications.initialize(initializationSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_androidChannel);
    await androidPlugin?.requestNotificationsPermission();

    _localNotificationsInitialized = true;
  }

  void _initializeForegroundMessageListener() {
    if (_foregroundListenerInitialized) return;
    _foregroundListenerInitialized = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      final androidNotification = notification?.android;

      final title = notification?.title ?? message.data['title']?.toString();
      final body = notification?.body ?? message.data['body']?.toString();

      if (title == null && body == null) return;

      await _localNotifications.show(
        notification.hashCode,
        title ?? 'Madrasti Plus',
        body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: androidNotification?.smallIcon,
          ),
        ),
      );
    });
  }

  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppNotification.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    });
  }

  Future<void> markAsRead(String notificationId) {
    return _notificationsCollection.doc(notificationId).set(
      {'isRead': true},
      SetOptions(merge: true),
    );
  }

  Future<void> createAttendanceNotifications({
    required AttendanceRecord record,
  }) async {
    try {
      final parentsSnapshot = await _usersCollection
          .where('role', isEqualTo: 'parent')
          .where('linkedStudentIds', arrayContains: record.studentId)
          .get();

      if (parentsSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      final now = DateTime.now();
      final isCheckIn = record.isCheckIn;

      for (final parentDoc in parentsSnapshot.docs) {
        final appUser = AppUser.fromJson({
          ...parentDoc.data(),
          'id': parentDoc.id,
        });
        final docRef = _notificationsCollection.doc();
        final notification = AppNotification(
          id: docRef.id,
          userId: appUser.id,
          studentId: record.studentId,
          studentName: record.studentName,
          type: record.type,
          title: isCheckIn ? 'تم تسجيل حضور' : 'تم تسجيل خروج',
          body: isCheckIn
              ? 'تم تسجيل حضور ${record.studentName} إلى المدرسة.'
              : 'تم تسجيل خروج ${record.studentName} من المدرسة.',
          createdAt: now,
        );

        batch.set(docRef, notification.toJson());
      }

      await batch.commit();
    } catch (error, stackTrace) {
      debugPrint('Failed to create attendance notifications: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
