import 'dart:convert';
import 'package:http/http.dart' as http;

class SkateshopApiService {
  static const String _baseUrl =
      'https://skateshop-backend-663618957788.asia-southeast1.run.app';

  // Fetch products from the backend API
  static Future<List<dynamic>> fetchProducts() async {
    final url = Uri.parse('$_baseUrl/products');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData is List) {
          return responseData;
        } else if (responseData is Map &&
            responseData.containsKey('products')) {
          return responseData['products'];
        }
      }
      throw Exception('Gagal mengambil data produk');
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Tidak dapat mengambil data produk dari server.');
    }
  }
}
