import 'dart:convert';
import 'package:http/http.dart' as http;

class GooglePlacesService {
  // Note: Dalam production, API key harus disimpan secara aman
  // Untuk demo, menggunakan API key dummy atau bisa menggunakan free alternative
  static const String _apiKey =
      'YOUR_GOOGLE_PLACES_API_KEY'; // Ganti dengan API key nyata
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Alternative: Menggunakan Overpass API untuk data OpenStreetMap (gratis)
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  static Future<List<Map<String, dynamic>>> searchSkateshopsNearYogyakarta({
    double latitude = -7.7956, // Default: Yogyakarta
    double longitude = 110.3695,
    int radius = 10000, // 10km
  }) async {
    try {
      // Menggunakan Overpass API (OpenStreetMap) sebagai alternatif gratis
      return await _searchWithOverpass(latitude, longitude, radius);
    } catch (e) {
      print('Error searching skateshops: $e');
      // Fallback ke data dummy jika API gagal
      return _getFallbackSkateshops(latitude, longitude);
    }
  }

  static Future<List<Map<String, dynamic>>> _searchWithOverpass(
    double latitude,
    double longitude,
    int radius,
  ) async {
    // Query Overpass untuk mencari toko yang berkaitan dengan skateboard/sport
    final query = '''
[out:json][timeout:25];
(
  node["shop"~"sports|skateboard|bicycle"]["name"~"(?i)(skate|board|sport|bike)"]
    (around:$radius,$latitude,$longitude);
  way["shop"~"sports|skateboard|bicycle"]["name"~"(?i)(skate|board|sport|bike)"]
    (around:$radius,$latitude,$longitude);
  relation["shop"~"sports|skateboard|bicycle"]["name"~"(?i)(skate|board|sport|bike)"]
    (around:$radius,$latitude,$longitude);
);
out center meta;
''';

    final response = await http.post(
      Uri.parse(_overpassUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'data=$query',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final elements = data['elements'] as List<dynamic>;

      return elements.map<Map<String, dynamic>>((element) {
        final tags = element['tags'] ?? {};
        final lat = element['lat'] ?? element['center']?['lat'] ?? latitude;
        final lon = element['lon'] ?? element['center']?['lon'] ?? longitude;

        return {
          'id': element['id'].toString(),
          'name': tags['name'] ?? 'Toko Sport',
          'address': _buildAddress(tags),
          'latitude': lat.toDouble(),
          'longitude': lon.toDouble(),
          'phone': tags['phone'] ?? '',
          'type': _getShopType(tags),
          'rating': 4.0 + (element['id'] % 10) / 10, // Simulasi rating
          'description': _getDescription(tags),
          'hours': tags['opening_hours'] ?? 'Informasi jam buka tidak tersedia',
          'website': tags['website'] ?? '',
          'source': 'OpenStreetMap',
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch data from Overpass API');
    }
  }

  static String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];

    if (tags['addr:street'] != null) {
      parts.add('Jl. ${tags['addr:street']}');
    }
    if (tags['addr:housenumber'] != null) {
      parts.add('No. ${tags['addr:housenumber']}');
    }
    if (tags['addr:city'] != null) {
      parts.add(tags['addr:city']);
    } else if (tags['addr:suburb'] != null) {
      parts.add(tags['addr:suburb']);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Alamat tidak tersedia';
  }

  static String _getShopType(Map<String, dynamic> tags) {
    final shop = tags['shop']?.toString().toLowerCase() ?? '';
    final name = tags['name']?.toString().toLowerCase() ?? '';

    if (shop.contains('skateboard') || name.contains('skate')) {
      return 'skateshop';
    } else if (shop.contains('sports') || name.contains('sport')) {
      return 'sports';
    } else if (shop.contains('bicycle') || name.contains('bike')) {
      return 'bicycle';
    }
    return 'toko';
  }

  static String _getDescription(Map<String, dynamic> tags) {
    final shop = tags['shop']?.toString() ?? '';
    final sport = tags['sport']?.toString() ?? '';

    if (shop.contains('skateboard')) {
      return 'Toko skateboard dengan berbagai perlengkapan skating';
    } else if (shop.contains('sports')) {
      return 'Toko olahraga dengan koleksi peralatan sport lengkap';
    } else if (sport.isNotEmpty) {
      return 'Tempat olahraga untuk aktivitas $sport';
    }
    return 'Toko dengan berbagai perlengkapan olahraga';
  }

  // Fallback data untuk Yogyakarta jika API gagal
  static List<Map<String, dynamic>> _getFallbackSkateshops(
    double latitude,
    double longitude,
  ) {
    return [
      {
        'id': 'fallback_1',
        'name': 'Sport Station Malioboro',
        'address': 'Jl. Malioboro No. 123, Yogyakarta',
        'latitude': -7.7956,
        'longitude': 110.3695,
        'phone': '+62 274 555001',
        'type': 'sports',
        'rating': 4.2,
        'description': 'Toko olahraga dengan koleksi skateboard dan aksesoris',
        'hours': 'Senin-Minggu: 10:00-22:00',
        'website': '',
        'source': 'Fallback',
      },
      {
        'id': 'fallback_2',
        'name': 'Planet Sports Jogja',
        'address': 'Jl. Kaliurang No. 45, Sleman',
        'latitude': -7.7689,
        'longitude': 110.3756,
        'phone': '+62 274 555002',
        'type': 'sports',
        'rating': 4.0,
        'description': 'Planet sports dengan berbagai peralatan skating',
        'hours': 'Senin-Minggu: 09:00-21:00',
        'website': '',
        'source': 'Fallback',
      },
      {
        'id': 'fallback_3',
        'name': 'Decathlon Yogyakarta',
        'address': 'Jl. Laksda Adisucipto, Yogyakarta',
        'latitude': -7.7887,
        'longitude': 110.4081,
        'phone': '+62 274 555003',
        'type': 'sports',
        'rating': 4.5,
        'description': 'Toko olahraga internasional dengan section skateboard',
        'hours': 'Senin-Minggu: 10:00-22:00',
        'website': 'www.decathlon.co.id',
        'source': 'Fallback',
      },
      {
        'id': 'fallback_4',
        'name': 'Jogja Skate Community',
        'address': 'Alun-alun Kidul, Yogyakarta',
        'latitude': -7.8134,
        'longitude': 110.3621,
        'phone': '+62 274 555004',
        'type': 'komunitas',
        'rating': 4.3,
        'description': 'Komunitas skater Yogyakarta dengan rental board',
        'hours': 'Senin-Minggu: 16:00-22:00',
        'website': '',
        'source': 'Fallback',
      },
      {
        'id': 'fallback_5',
        'name': 'BMX & Skate Corner',
        'address': 'Jl. Parangtritis Km 5, Bantul',
        'latitude': -7.8753,
        'longitude': 110.3389,
        'phone': '+62 274 555005',
        'type': 'skateshop',
        'rating': 4.1,
        'description': 'Spesialis BMX dan skateboard dengan workshop',
        'hours': 'Senin-Sabtu: 14:00-21:00',
        'website': '',
        'source': 'Fallback',
      },
    ];
  }

  // Fungsi untuk Google Places API (jika memiliki API key)
  static Future<List<Map<String, dynamic>>> _searchWithGooglePlaces(
    double latitude,
    double longitude,
    int radius,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/nearbysearch/json?location=$latitude,$longitude&radius=$radius&keyword=skateboard+skate+sport&type=store&key=$_apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;

      return results.map<Map<String, dynamic>>((place) {
        return {
          'id': place['place_id'],
          'name': place['name'] ?? 'Toko Tidak Dikenal',
          'address': place['vicinity'] ?? 'Alamat tidak tersedia',
          'latitude': place['geometry']['location']['lat'].toDouble(),
          'longitude': place['geometry']['location']['lng'].toDouble(),
          'phone': '', // Perlu detail request terpisah
          'type': 'toko',
          'rating': place['rating']?.toDouble() ?? 0.0,
          'description': place['types']?.join(', ') ?? '',
          'hours': '', // Perlu detail request terpisah
          'website': '',
          'source': 'Google Places',
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch data from Google Places API');
    }
  }
}
