import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/NotificationService.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  ProductDetailPage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? product['title'] ?? 'Detail Produk'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildProductImage(),
              ),
            ),
            SizedBox(height: 20),

            // Product Name
            Text(
              product['name'] ?? product['title'] ?? 'Produk Tanpa Nama',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),

            // Product Price
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_money,
                      color: Colors.green.shade700, size: 20),
                  Text(
                    _formatPrice(product['price']),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Product Description
            if (product['description'] != null) ...[
              Text(
                'Deskripsi Produk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  product['description'] ?? 'Tidak ada deskripsi tersedia.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _buyNow(context),
                    icon: Icon(Icons.shopping_cart, color: Colors.white),
                    label: Text(
                      'Beli Sekarang',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _shareProduct(context),
                  icon: Icon(Icons.share, color: Colors.orange),
                  label: Text(
                    'Bagikan',
                    style: TextStyle(color: Colors.orange),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    side: BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final imageUrl = _getImageUrl();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.skateboarding,
            size: 64,
            color: Colors.orange,
          ),
          SizedBox(height: 8),
          Text(
            'Gambar Produk',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String? _getImageUrl() {
    if (product['imageUrls'] != null &&
        product['imageUrls'] is List &&
        product['imageUrls'].isNotEmpty) {
      return product['imageUrls'][0];
    }
    if (product['image'] != null) {
      return product['image'];
    }
    return null;
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Harga tidak tersedia';

    if (price is String) {
      // If price already contains currency symbol, return as is
      if (price.contains('\$') || price.contains('Rp')) {
        return price;
      }
      // Try to parse as number
      final numPrice = double.tryParse(price);
      if (numPrice != null) {
        return '\$${numPrice.toStringAsFixed(2)}';
      }
      return price;
    }

    if (price is num) {
      return '\$${price.toStringAsFixed(2)}';
    }

    return price.toString();
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

  void _shareProduct(BuildContext context) {
    final productName = product['name'] ?? product['title'] ?? 'Produk';
    final productPrice = _formatPrice(product['price']);
    final productUrl = product['url'] ?? '';

    final shareText =
        'Lihat produk ini: $productName - $productPrice\n$productUrl';

    NotificationService.showSuccess(
      'Produk Dibagikan',
      'Informasi $productName berhasil dibagikan',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur berbagi: $shareText'),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
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
}
