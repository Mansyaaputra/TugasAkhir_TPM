// services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ApiService.dart';

class ProductService {
  static const String _apiUrl =
      'https://skateshop-backend-663618957788.asia-southeast1.run.app/api/products';

  /// Primary method to fetch products
  /// Now uses the improved SkateshopApiService
  static Future<List<dynamic>> fetchProducts() async {
    try {
      print('Fetching products using SkateshopApiService...');
      return await SkateshopApiService.fetchProducts();
    } catch (e) {
      print('Exception in ProductService.fetchProducts: $e');
      throw Exception('Gagal mengambil data produk: ${e.toString()}');
    }
  }

  /// Legacy method that directly calls the API
  /// Kept for backward compatibility
  static Future<List<dynamic>> fetchProductsLegacy() async {
    try {
      print('Fetching products from API using legacy method...');
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      print('API Response Status: ${response.statusCode}');
      print('API Response Body Length: ${response.body.length}');
      print(
          'API Response Body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        print('Response data type: ${responseData.runtimeType}');
        print('Response data: $responseData');

        List<dynamic> data;

        // Handle different response formats
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          data = responseData['data'] ?? [];
        } else if (responseData is Map &&
            responseData.containsKey('products')) {
          data = responseData['products'] ?? [];
        } else {
          print('Unexpected response format, throwing error');
          throw Exception('Format respons API tidak valid');
        }

        print('Decoded data length: ${data.length}');

        if (data.isNotEmpty) {
          print('First product sample: ${data[0]}');
          // Transform API data to match our expected format
          return data.map((item) => _transformProductData(item)).toList();
        } else {
          print('API returned empty array, throwing error');
          throw Exception('Server tidak mengembalikan data produk');
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Error dari server: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchProductsLegacy: $e');
      throw Exception('Gagal mengambil data produk: ${e.toString()}');
    }
  }

  /// Transform API product data to match our expected format
  /// Note: This is primarily kept for legacy compatibility
  /// The main transformation is now handled in SkateshopApiService
  static Map<String, dynamic> _transformProductData(dynamic item) {
    if (item is! Map<String, dynamic>) {
      return {
        'title': 'Produk Skateboard',
        'name': 'Produk Skateboard',
        'price': '\$0.00',
        'description': 'Deskripsi produk skateboard',
        'image': 'https://picsum.photos/300/200?random=1',
        'imageUrls': ['https://picsum.photos/300/200?random=1'],
        'url': 'https://example.com/product',
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };
    }

    return {
      'title': item['name'] ?? item['title'] ?? 'Produk Skateboard',
      'name': item['name'] ?? item['title'] ?? 'Produk Skateboard',
      'price': item['price'] != null
          ? (item['price'].toString().startsWith('\$')
              ? item['price']
              : '\$${item['price']}')
          : '\$0.00',
      'description': item['description'] ?? 'Deskripsi produk skateboard',
      'image': item['image'] ??
          item['imageUrl'] ??
          'https://picsum.photos/300/200?random=1',
      'imageUrls': item['imageUrls'] ??
          (item['image'] != null
              ? [item['image']]
              : ['https://picsum.photos/300/200?random=1']),
      'url': item['url'] ?? 'https://example.com/product',
      'id': item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }
}
