import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/NotificationService.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  ProductDetailPage({required this.product});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Map<String, dynamic> product;
  int _qty = 1;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedPayment = 'cod';

  @override
  void initState() {
    super.initState();
    product = widget.product;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Hapus judul/tulisan pada navbar
        title: null,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gambar produk proporsional, tinggi, center
            Padding(
              padding: const EdgeInsets.only(
                  top: 24, left: 48, right: 48, bottom: 8),
              child: AspectRatio(
                aspectRatio: 1 / 1.5, // lebih kecil lagi
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    product['image'] ?? '',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported,
                          size: 36, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            // Nama produk
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                product['name'] != null
                    ? product['name'].toString().toUpperCase()
                    : '-',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Harga produk (jika ada)
            if (product['price'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  _formatPrice(product['price']),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Pilih jumlah
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Qty',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            if (_qty > 1) setState(() => _qty--);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('$_qty', style: TextStyle(fontSize: 16)),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() => _qty++);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Form Nama, Alamat, No HP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Alamat Pengiriman',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'No. Handphone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Metode Pembayaran',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPayment,
                    items: [
                      DropdownMenuItem(
                          value: 'cod', child: Text('Bayar di Tempat (COD)')),
                      DropdownMenuItem(
                          value: 'transfer', child: Text('Transfer Bank')),
                      DropdownMenuItem(
                          value: 'ewallet',
                          child: Text('E-Wallet (OVO, GoPay, DANA)')),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedPayment = val ?? 'cod'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
                  ),
                ],
              ),
            ),
            // Tombol beli (opsional)
            SizedBox(height: 24),
            SizedBox(
              width: 180,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _buyNow(context),
                icon: Icon(Icons.shopping_cart_checkout),
                label: Text('Beli Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _buyNow(BuildContext context) async {
    final productName = product['name'] ?? product['title'] ?? 'Produk';

    NotificationService.showInfo(
      'Pembelian Dimulai',
      'Mengarahkan ke halaman pembelian untuk $productName',
    );

    final url = product['url'];
    if (url != null && url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          NotificationService.showSuccess(
            'Link Terbuka',
            'Halaman pembelian $productName berhasil dibuka',
          );
        } else {
          NotificationService.showError(
            'Gagal Membuka Link',
            'Tidak dapat membuka link produk $productName',
          );
          _showErrorDialog(context, 'Tidak dapat membuka link produk');
        }
      } catch (e) {
        NotificationService.showError(
          'Error Beli Produk',
          'Terjadi kesalahan saat membuka link: $e',
        );
        _showErrorDialog(context, 'Error: $e');
      }
    } else {
      NotificationService.showWarning(
        'Link Tidak Tersedia',
        'Link produk $productName tidak tersedia saat ini',
      );
      _showErrorDialog(context, 'Link produk tidak tersedia');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Informasi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Harga tidak tersedia';
    if (price is String && price.trim().startsWith('4')) {
      final numStr = price.replaceAll(RegExp(r'[^0-9.]'), '');
      final double? usd = double.tryParse(numStr);
      if (usd != null) {
        final int rupiah = (usd * 16000).round();
        return 'Rp${rupiah.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ".")}';
      }
    }
    if (price is double) {
      final int rupiah = (price * 16000).round();
      return 'Rp${rupiah.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ".")}';
    }
    int? numPrice = int.tryParse(price.toString());
    if (numPrice != null) {
      return 'Rp${numPrice.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ".")}';
    }
    return price.toString();
  }
}
