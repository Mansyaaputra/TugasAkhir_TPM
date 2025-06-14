// services/product_service.dart
import 'ApiService.dart';

class ProductService {
  /// Fetch products using SkateshopApiService (langsung ke /products)
  static Future<List<dynamic>> fetchProducts() async {
    try {
      final products = await SkateshopApiService.fetchProducts();
      // Transform agar field sesuai kebutuhan aplikasi (name, price, description, image, category, dst)
      return products.map((item) => _transformProductData(item)).toList();
    } catch (e) {
      print('Exception in ProductService.fetchProducts: $e');
      throw Exception('Gagal mengambil data produk: ${e.toString()}');
    }
  }

  static Map<String, dynamic> _transformProductData(dynamic item) {
    if (item is! Map<String, dynamic>) {
      return {
        'title': 'Produk Skateboard',
        'name': 'Produk Skateboard',
        'price': 0,
        'description': 'Deskripsi produk skateboard',
        'image': 'https://picsum.photos/300/200?random=1',
        'category': 'lainnya',
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };
    }
    return {
      'title': item['name'] ?? 'Produk Skateboard',
      'name': item['name'] ?? 'Produk Skateboard',
      'price': item['price'] ?? 0,
      'description': item['description'] ?? 'Deskripsi produk skateboard',
      'image': item['imageUrl'] ??
          item['image'] ??
          'https://picsum.photos/300/200?random=1',
      'category': item['category'] ?? 'lainnya',
      'id': item['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }
}
