import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'ProductListPage.dart';
import 'ConversionPage.dart';
import 'ProfilPage.dart';
import 'SkateshopMapPage.dart';
import 'SensorPage.dart';
import '../services/NotificationService.dart';
import 'AllOrderDetailPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/AuthService.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idx = 0;
  int _unreadNotificationCount = 0;
  List<Map<String, dynamic>> _orders = [];
  String? _currentUser;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load current user and orders first
    await _loadCurrentUserAndOrders();

    // Initialize pages with proper callback
    _pages = [
      ProductListPage(onAddOrder: _addOrder),
      ConversionPage(),
      SensorPage(),
      SkateshopMapPage(),
      ProfilePage(),
    ];

    _loadUnreadNotificationCount();
    NotificationService.addListener(_onNotificationUpdate);

    // Initialize notification service with permission request
    await _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.initialize();

    // Check if notifications are enabled
    final enabled = await NotificationService.areNotificationsEnabled();
    if (!enabled) {
      _showNotificationPermissionDialog();
    }

    // Add welcome notification
    Future.delayed(Duration(seconds: 2), () {
      NotificationService.showSuccess(
        'Selamat Datang!',
        'Selamat datang di SkateShop. Jelajahi produk skateboard terbaik!',
      );
    });
  }

  void _showNotificationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications, color: Colors.blue),
            SizedBox(width: 8),
            Text('Izin Notifikasi'),
          ],
        ),
        content: Text(
          'Aplikasi membutuhkan izin notifikasi untuk mengirim update produk, promo, dan informasi penting lainnya.\n\n'
          'Notifikasi otomatis akan dikirim setiap 2 menit dengan konten menarik.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              NotificationService.openNotificationSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child:
                Text('Buka Pengaturan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    NotificationService.removeListener(_onNotificationUpdate);
    // Don't stop periodic notifications when HomePage is disposed
    // They should continue running in background
    super.dispose();
  }

  void _onNotificationUpdate(List<NotificationModel> notifications) {
    if (mounted) {
      setState(() {
        _unreadNotificationCount = notifications.where((n) => !n.isRead).length;
      });
    }
  }

  void _loadUnreadNotificationCount() {
    final unreadNotifications = NotificationService.getUnreadNotifications();
    setState(() {
      _unreadNotificationCount = unreadNotifications.length;
    });
  }

  Future<void> _loadCurrentUserAndOrders() async {
    try {
      // Menggunakan session untuk mendapatkan current user
      final user = await AuthService().getCurrentUser();
      print('Loading user and orders for: $user'); // Debug log

      setState(() {
        _currentUser = user;
      });

      // Load orders berdasarkan current user
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final ordersKey = 'orders_$user';
        final ordersJson = prefs.getString(ordersKey);

        print('Orders key: $ordersKey'); // Debug log
        print('Orders JSON: $ordersJson'); // Debug log

        if (ordersJson != null && ordersJson.isNotEmpty) {
          try {
            final List<dynamic> decoded = jsonDecode(ordersJson);
            final orders = decoded.cast<Map<String, dynamic>>();

            setState(() {
              _orders = orders;
            });

            print('Loaded ${orders.length} orders for user $user'); // Debug log
          } catch (e) {
            print('Error decoding orders JSON: $e');
            setState(() {
              _orders = [];
            });
          }
        } else {
          print('No orders found for user $user');
          setState(() {
            _orders = [];
          });
        }
      } else {
        print('No current user found');
        setState(() {
          _orders = [];
        });
      }
    } catch (e) {
      print('Error loading user and orders: $e');
      setState(() {
        _currentUser = null;
        _orders = [];
      });
    }
  }

  Future<void> _saveOrders() async {
    try {
      if (_currentUser == null) {
        print('Cannot save orders: no current user');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final ordersKey = 'orders_$_currentUser';
      final ordersJson = jsonEncode(_orders);

      await prefs.setString(ordersKey, ordersJson);

      print(
          'Saved ${_orders.length} orders for user $_currentUser'); // Debug log
      print('Orders key: $ordersKey'); // Debug log
    } catch (e) {
      print('Error saving orders: $e');
    }
  }

  void _addOrder(Map<String, dynamic> order) async {
    try {
      // Add timestamp and user info to order
      final orderWithMetadata = {
        ...order,
        'timestamp': DateTime.now().toIso8601String(),
        'user': _currentUser,
        'orderId': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      setState(() {
        _orders.add(orderWithMetadata);
      });

      await _saveOrders();

      // Show success notification
      NotificationService.showSuccess(
        'Pesanan Ditambahkan',
        'Produk ${order['name'] ?? 'Unknown'} berhasil ditambahkan ke pesanan',
      );

      print(
          'Added order for user $_currentUser: ${order['name']}'); // Debug log
    } catch (e) {
      print('Error adding order: $e');

      // Show error notification
      NotificationService.showError(
        'Error',
        'Gagal menambahkan pesanan: $e',
      );
    }
  }

  // Method untuk debug - bisa dipanggil dari UI
  Future<void> _debugOrdersData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      print('=== DEBUG ORDERS DATA ===');
      print('Current user: $_currentUser');
      print('Orders in memory: ${_orders.length}');
      print('All SharedPreferences keys: $keys');

      // Show all order keys
      final orderKeys = keys.where((key) => key.startsWith('orders_')).toList();
      print('Order keys found: $orderKeys');

      for (String key in orderKeys) {
        final data = prefs.getString(key);
        print('$key: $data');
      }
      print('========================');
    } catch (e) {
      print('Error in debug: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: _pages.isNotEmpty
          ? _pages[_idx]
          : Center(child: CircularProgressIndicator()),
      // Add debug button in development mode
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
              mini: true,
              onPressed: _debugOrdersData,
              child: Icon(Icons.bug_report, color: Colors.white),
              backgroundColor: Colors.red,
              tooltip: 'Debug Orders Data',
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.indigo.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 9,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _idx == 0
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.shopping_bag_outlined, size: 20),
                      ),
                      SizedBox(width: 2),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AllOrderDetailPage(orders: _orders),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.receipt_long,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              label: 'Produk',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _idx == 1
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.swap_horiz, size: 20),
              ),
              label: 'Konversi',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _idx == 2
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.sensors, size: 20),
              ),
              label: 'Sensor',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _idx == 3
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.map_outlined, size: 20),
              ),
              label: 'Lokasi',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _idx == 4
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline, size: 20),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
