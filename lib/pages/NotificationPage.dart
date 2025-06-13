import 'package:flutter/material.dart';
import '../services/NotificationService.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> _notifications = [];
  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = [
    'Semua',
    'Belum Dibaca',
    'Produk',
    'Pesanan',
    'Promosi',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    NotificationService.addListener(_onNotificationUpdate);
  }

  @override
  void dispose() {
    NotificationService.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  void _onNotificationUpdate(List<NotificationModel> notifications) {
    if (mounted) {
      setState(() {
        _notifications = notifications;
      });
    }
  }

  void _loadNotifications() {
    setState(() {
      _notifications = NotificationService.getNotifications();
    });
  }

  List<NotificationModel> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'Belum Dibaca':
        return _notifications.where((n) => !n.isRead).toList();
      case 'Produk':
        return _notifications
            .where((n) => n.type == NotificationType.product)
            .toList();
      case 'Pesanan':
        return _notifications
            .where((n) => n.type == NotificationType.order)
            .toList();
      case 'Promosi':
        return _notifications
            .where((n) => n.type == NotificationType.promotion)
            .toList();
      default:
        return _notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Notifikasi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8,
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: Colors.blue.shade100,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.blue.shade900
                          : Colors.blueGrey.shade700,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
                  );
                }).toList(),
              ),
            ),
            // List Notifikasi
            Expanded(
              child: _filteredNotifications.isEmpty
                  ? Center(child: Text('Tidak ada notifikasi'))
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notif = _filteredNotifications[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            leading: Icon(
                              notif.type == NotificationType.product
                                  ? Icons.shopping_bag
                                  : notif.type == NotificationType.order
                                      ? Icons.receipt_long
                                      : notif.type == NotificationType.promotion
                                          ? Icons.local_offer
                                          : Icons.notifications,
                              color: Colors.blue,
                              size: 32,
                            ),
                            title: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  notif.message,
                                  style: TextStyle(
                                      color: Colors.blueGrey.shade700),
                                ),
                                if (notif.actionLabel != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: ElevatedButton(
                                      onPressed: notif.onAction,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 10),
                                      ),
                                      child: Text(
                                        notif.actionLabel!,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: notif.isRead
                                ? null
                                : Icon(Icons.circle,
                                    color: Colors.blue, size: 14),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Hapus Semua Notifikasi'),
          ],
        ),
        content: Text(
            'Apakah Anda yakin ingin menghapus semua notifikasi? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              NotificationService.clearAll();
              Navigator.pop(context);
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
