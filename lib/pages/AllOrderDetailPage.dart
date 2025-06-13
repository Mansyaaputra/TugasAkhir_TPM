import 'package:flutter/material.dart';

class AllOrderDetailPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  const AllOrderDetailPage({Key? key, required this.orders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Daftar Pesanan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: orders.isEmpty
          ? Center(child: Text('Belum ada pesanan'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final order = orders[i];
                return Card(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order['productImage'] ?? '',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    ),
                    title: Text(order['productName'] ?? '-',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jumlah: ${order['quantity']}'),
                        Text('Nama: ${order['customerName']}'),
                        Text('Alamat: ${order['address']}'),
                        Text('No HP: ${order['phoneNumber']}'),
                        Text('Pembayaran: ${order['paymentMethod']}'),
                        Text('Status: Proses',
                            style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
