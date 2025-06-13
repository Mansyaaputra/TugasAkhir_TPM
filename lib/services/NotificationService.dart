import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

// Conditional imports
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    if (dart.library.html) 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart'
    if (dart.library.html) 'package:flutter/widgets.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  static bool _initialized = false;
  static Timer? _periodicTimer;

  /// Inisialisasi notifikasi lokal dengan request permission
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        // Web implementation - minimal setup
        _initialized = true;
        print('Notification service initialized for web');
        _startPeriodicNotifications();
        return;
      }

      // Mobile implementation
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Request notification permission untuk Android 13+
      await _requestNotificationPermission();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          print('Notification tapped: ${response.payload}');
        },
      );

      // Create notification channel untuk Android
      await _createNotificationChannel();

      _initialized = true;
      print('Notification service initialized successfully');

      // Start periodic notifications
      _startPeriodicNotifications();
    } catch (e) {
      print('Error initializing notifications: $e');
      _initialized = true; // Set true anyway to prevent repeated attempts
    }
  }

  /// Request permission untuk notifikasi
  static Future<bool> _requestNotificationPermission() async {
    if (kIsWeb) return true;

    try {
      // Check current permission status
      final permission = await Permission.notification.status;

      if (permission.isDenied) {
        // Request permission
        final newPermission = await Permission.notification.request();
        return newPermission.isGranted;
      }

      return permission.isGranted;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return true; // Return true as fallback
    }
  }

  /// Create notification channel untuk Android
  static Future<void> _createNotificationChannel() async {
    if (kIsWeb || flutterLocalNotificationsPlugin == null) return;

    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'skateshop_channel',
        'SkateShop Notifications',
        description: 'Notifikasi untuk aplikasi SkateShop',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await flutterLocalNotificationsPlugin!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      print('Error creating notification channel: $e');
    }
  }

  /// Start periodic notifications setiap 2 menit
  static void _startPeriodicNotifications() {
    _periodicTimer?.cancel(); // Cancel existing timer

    _periodicTimer = Timer.periodic(Duration(minutes: 2), (timer) {
      _showRandomNotification();
    });

    print('Periodic notifications started (every 2 minutes)');
  }

  /// Stop periodic notifications
  static void stopPeriodicNotifications() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    print('Periodic notifications stopped');
  }

  /// Show random notification
  static void _showRandomNotification() {
    final List<Map<String, String>> randomNotifications = [
      {
        'title': 'Promo Spesial!',
        'body': 'Diskon 20% untuk semua aksesoris skateboard. Berlaku hari ini!'
      },
      {
        'title': 'Reminder',
        'body': 'Sudahkah kamu check produk favorit hari ini?'
      },
      {
        'title': 'Komunitas Skater',
        'body': 'Bergabunglah dengan komunitas skater di area terdekat!'
      },
      {
        'title': 'Maintenance Board',
        'body':
            'Waktu yang tepat untuk cek kondisi bearing dan wheels skateboard kamu.'
      },
    ];

    final random =
        DateTime.now().millisecondsSinceEpoch % randomNotifications.length;
    final notification = randomNotifications[random];

    showLocalNotification(
      title: notification['title']!,
      body: notification['body']!,
    );

    // Add to internal notification list
    addNotification(
      title: notification['title']!,
      message: notification['body']!,
      type: NotificationType.info,
      showSystemNotification: false, // Already shown above
    );
  }

  /// Tampilkan notifikasi lokal di system tray
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (kIsWeb) {
        // Web fallback - just log
        print('Web notification: $title - $body');
        return;
      }

      await initialize();

      if (flutterLocalNotificationsPlugin == null) return;

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'skateshop_channel',
        'SkateShop Notifications',
        channelDescription: 'Notifikasi untuk aplikasi SkateShop',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'ticker',
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(body),
        playSound: true,
        enableVibration: true,
      );

      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin!.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  static final List<NotificationModel> _notifications = [];
  static final List<Function(List<NotificationModel>)> _listeners = [];

  /// Menambah listener untuk perubahan notifikasi
  static void addListener(Function(List<NotificationModel>) listener) {
    _listeners.add(listener);
  }

  /// Menghapus listener
  static void removeListener(Function(List<NotificationModel>) listener) {
    _listeners.remove(listener);
  }

  /// Memberi tahu semua listener tentang perubahan
  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener(List.from(_notifications));
    }
  }

  /// Menambahkan notifikasi baru
  static void addNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    String? actionLabel,
    VoidCallback? onAction,
    bool showSystemNotification = true,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      actionLabel: actionLabel,
      onAction: onAction,
    );

    _notifications.insert(0, notification);

    // Batasi maksimal 50 notifikasi
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }

    _notifyListeners();

    if (showSystemNotification) {
      showLocalNotification(title: title, body: message);
    }
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;

    try {
      final permission = await Permission.notification.status;
      return permission.isGranted;
    } catch (e) {
      print('Error checking notification permission: $e');
      return true;
    }
  }

  /// Open app settings for notification permission
  static Future<void> openNotificationSettings() async {
    if (kIsWeb) return;

    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  /// Mendapatkan semua notifikasi
  static List<NotificationModel> getNotifications() {
    return List.from(_notifications);
  }

  /// Mendapatkan notifikasi yang belum dibaca
  static List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Menandai notifikasi sebagai dibaca
  static void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notifyListeners();
    }
  }

  /// Menandai semua notifikasi sebagai dibaca
  static void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _notifyListeners();
  }

  /// Menghapus notifikasi
  static void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notifyListeners();
  }

  /// Menghapus semua notifikasi
  static void clearAll() {
    _notifications.clear();
    _notifyListeners();
  }

  /// Mendapatkan jumlah notifikasi yang belum dibaca
  static int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  // Metode helper untuk berbagai jenis notifikasi
  static void showSuccess(String title, String message,
      {String? actionLabel, VoidCallback? onAction}) {
    addNotification(
      title: title,
      message: message,
      type: NotificationType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showError(String title, String message,
      {String? actionLabel, VoidCallback? onAction}) {
    addNotification(
      title: title,
      message: message,
      type: NotificationType.error,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showWarning(String title, String message,
      {String? actionLabel, VoidCallback? onAction}) {
    addNotification(
      title: title,
      message: message,
      type: NotificationType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showInfo(String title, String message,
      {String? actionLabel, VoidCallback? onAction}) {
    addNotification(
      title: title,
      message: message,
      type: NotificationType.info,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showProductUpdate(String productName, String message) {
    addNotification(
      title: 'Update Produk',
      message: '$productName - $message',
      type: NotificationType.product,
      actionLabel: 'Lihat Produk',
      onAction: () {
        // Implementasi navigasi ke produk
      },
    );
  }

  static void showOrderNotification(String orderId, String status) {
    addNotification(
      title: 'Status Pesanan',
      message: 'Pesanan #$orderId - $status',
      type: NotificationType.order,
      actionLabel: 'Lihat Detail',
      onAction: () {
        // Implementasi navigasi ke detail pesanan
      },
    );
  }
}

enum NotificationType {
  info,
  success,
  warning,
  error,
  product,
  order,
  promotion,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionLabel;
  final VoidCallback? onAction;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionLabel,
    this.onAction,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel ?? this.actionLabel,
      onAction: onAction ?? this.onAction,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.product:
        return Icons.shopping_bag;
      case NotificationType.order:
        return Icons.receipt;
      case NotificationType.promotion:
        return Icons.local_offer;
      default:
        return Icons.info;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.product:
        return Colors.blue;
      case NotificationType.order:
        return Colors.purple;
      case NotificationType.promotion:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }
}
