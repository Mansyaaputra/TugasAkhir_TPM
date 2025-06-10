import 'dart:convert';
import 'package:http/http.dart' as http;

class SkateshopApiService {
  static const String _baseUrl =
      'https://skateshop-backend-663618957788.asia-southeast1.run.app';
  static const String _apiEndpoint = '/api/products';

  // Multiple possible API endpoints to try
  static const List<String> _possibleEndpoints = [
    '/api/products',
    '/products',
    '/api/v1/products',
    '/skateboard/products',
  ];

  /// Fetch products from the skateshop backend API
  /// Tries multiple endpoints and methods if the primary fails
  static Future<List<dynamic>> fetchProducts() async {
    // Try each possible endpoint
    for (String endpoint in _possibleEndpoints) {
      try {
        final url = Uri.parse('$_baseUrl$endpoint');
        print('Trying endpoint: $url');

        // Try GET first
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(Duration(seconds: 10));

        print('GET Response Status for $endpoint: ${response.statusCode}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          List<dynamic> products = _extractProductsFromResponse(responseData);

          if (products.isNotEmpty) {
            print(
                'Successfully fetched ${products.length} products from $endpoint');
            return products.map((item) => _transformProductData(item)).toList();
          }
        }

        // Try POST if GET fails and endpoint is the main API endpoint
        if (endpoint == _apiEndpoint) {
          final postResponse = await http
              .post(
                url,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: jsonEncode({}),
              )
              .timeout(Duration(seconds: 10));

          print(
              'POST Response Status for $endpoint: ${postResponse.statusCode}');

          if (postResponse.statusCode == 200) {
            final responseData = jsonDecode(postResponse.body);
            List<dynamic> products = _extractProductsFromResponse(responseData);

            if (products.isNotEmpty) {
              print(
                  'Successfully fetched ${products.length} products from POST $endpoint');
              return products
                  .map((item) => _transformProductData(item))
                  .toList();
            }
          }
        }
      } catch (e) {
        print('Error trying endpoint $endpoint: $e');
        continue;
      }
    }

    // If all API calls fail, throw an exception
    print('All API endpoints failed, no data available');
    throw Exception(
        'Tidak dapat mengambil data produk dari server. Periksa koneksi internet Anda.');
  }

  /// Extract products array from various response formats
  static List<dynamic> _extractProductsFromResponse(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    } else if (responseData is Map) {
      // Try common field names for product arrays
      for (String key in ['products', 'data', 'items', 'results']) {
        if (responseData.containsKey(key) && responseData[key] is List) {
          return responseData[key];
        }
      }
    }
    return [];
  }

  /// Transform API product data to match our expected format
  static Map<String, dynamic> _transformProductData(dynamic item) {
    if (item is! Map<String, dynamic>) {
      return _getDefaultProduct();
    }

    return {
      'title': item['name'] ??
          item['title'] ??
          item['productName'] ??
          'Produk Skateboard',
      'name': item['name'] ??
          item['title'] ??
          item['productName'] ??
          'Produk Skateboard',
      'price': _formatPrice(item['price'] ?? item['cost'] ?? item['amount']),
      'description': item['description'] ??
          item['desc'] ??
          'Deskripsi produk skateboard berkualitas tinggi',
      'image': _getImageUrl(item),
      'imageUrls': _getImageUrls(item),
      'url': item['url'] ??
          item['link'] ??
          item['productUrl'] ??
          'https://example.com/product',
      'id': item['id'] ??
          item['productId'] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
    };
  }

  /// Format price to ensure it has proper currency symbol
  static String _formatPrice(dynamic price) {
    if (price == null) return '\$0.00';

    String priceStr = price.toString();
    if (priceStr.startsWith('\$') || priceStr.startsWith('Rp')) {
      return priceStr;
    }

    // Try to parse as number and format
    try {
      double priceNum =
          double.parse(priceStr.replaceAll(RegExp(r'[^\d.]'), ''));
      return '\$${priceNum.toStringAsFixed(2)}';
    } catch (e) {
      return '\$0.00';
    }
  }

  /// Extract image URL from various fields
  static String _getImageUrl(Map<String, dynamic> item) {
    List<String> imageFields = [
      'image',
      'imageUrl',
      'photo',
      'picture',
      'thumbnail',
      'img'
    ];

    for (String field in imageFields) {
      if (item.containsKey(field) && item[field] != null) {
        String imageUrl = item[field].toString();
        if (imageUrl.isNotEmpty && _isValidImageUrl(imageUrl)) {
          return imageUrl;
        }
      }
    }

    // Return a random placeholder image
    return 'https://picsum.photos/300/200?random=${DateTime.now().millisecondsSinceEpoch % 1000}';
  }

  /// Extract multiple image URLs
  static List<String> _getImageUrls(Map<String, dynamic> item) {
    if (item.containsKey('imageUrls') && item['imageUrls'] is List) {
      return List<String>.from(item['imageUrls']);
    }

    String mainImage = _getImageUrl(item);
    return [mainImage];
  }

  /// Check if URL is a valid image URL
  static bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;

    // Check if it's a valid URL format
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get default product structure
  static Map<String, dynamic> _getDefaultProduct() {
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

  /// Legacy method for compatibility
  @deprecated
  static Future<List<dynamic>> runScraperAndGetData() async {
    return await fetchProducts();
  }

  /// Legacy method for compatibility
  @deprecated
  static Future<List<dynamic>> getLastRunData() async {
    return await fetchProducts();
  }
}
