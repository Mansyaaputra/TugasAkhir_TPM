import 'package:flutter/material.dart';
import 'ProductListPage.dart';
import 'ConversionPage.dart';
import 'ProfilPage.dart';
import 'NotificationPage.dart';
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
    _loadCurrentUserAndOrders();
    _pages = [
      ProductListPage(onAddOrder: _addOrder),
      ConversionPage(),
      SensorPage(),
      SkateshopMapPage(),
      NotificationPage(),
      ProfilePage(),
    ];
    _loadUnreadNotificationCount();
    NotificationService.addListener(_onNotificationUpdate);
    // Tambahkan notifikasi selamat datang dan demo
    Future.delayed(Duration(seconds: 1), () {
      NotificationService.showSuccess(
        'Selamat Datang!',
        'Selamat datang di SkateShop. Jelajahi produk skateboard terbaik!',
      );
    });

    // Tambahkan notifikasi demo produk dan promosi
    Future.delayed(Duration(seconds: 3), () {
      NotificationService.showProductUpdate(
        'Papan Skateboard Pro',
        'Produk baru dengan teknologi terkini telah tersedia!',
      );
    });

    Future.delayed(Duration(seconds: 5), () {
      NotificationService.addNotification(
        title: 'Promosi Spesial!',
        message:
            'Diskon 25% untuk semua helm keselamatan. Berlaku hingga akhir bulan!',
        type: NotificationType.promotion,
        actionLabel: 'Lihat Promo',
        onAction: () {
          // Navigate to promo page
        },
      );
    });

    Future.delayed(Duration(seconds: 7), () {
      NotificationService.showOrderNotification(
        'ORD001',
        'Pesanan sedang dikemas dan akan segera dikirim',
      );
    });
  }

  @override
  void dispose() {
    NotificationService.removeListener(_onNotificationUpdate);
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
    final user = await AuthService().getCurrentUser();
    setState(() {
      _currentUser = user;
    });
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getString('orders_$user');
      if (ordersJson != null) {
        final List<dynamic> decoded = jsonDecode(ordersJson);
        setState(() {
          _orders = decoded.cast<Map<String, dynamic>>();
        });
      }
    }
  }

  Future<void> _saveOrders() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('orders_$_currentUser', jsonEncode(_orders));
  }

  void _addOrder(Map<String, dynamic> order) async {
    setState(() {
      _orders.add(order);
    });
    await _saveOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: _pages[_idx],
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
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _idx == 0
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shopping_bag_outlined, size: 24),
                  ),
                  SizedBox(width: 4),
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
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long,
                          size: 22, color: Colors.white),
                    ),
                  ),
                ],
              ),
              label: 'Produk',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _idx == 1
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.swap_horiz, size: 24),
              ),
              label: 'Konversi',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _idx == 2
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.sensors, size: 24),
              ),
              label: 'Sensor',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _idx == 3
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.map_outlined, size: 24),
              ),
              label: 'Lokasi',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _idx == 4
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.notifications_outlined, size: 24),
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$_unreadNotificationCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Notifikasi',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _idx == 5
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_outline, size: 24),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
