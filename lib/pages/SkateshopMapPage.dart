import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../services/NotificationService.dart';
import '../services/GooglePlacesService.dart';

class SkateshopMapPage extends StatefulWidget {
  @override
  _SkateshopMapPageState createState() => _SkateshopMapPageState();
}

class _SkateshopMapPageState extends State<SkateshopMapPage> {
  Position? _currentPosition;
  bool _isLoading = true;
  String _locationStatus = '';
  List<Map<String, dynamic>> _nearbyShops = [];
  String _selectedFilter = 'semua';
  Map<String, dynamic>? _selectedShop;
  bool _showRoute = false;
  String _routeInfo = '';

  final List<Map<String, String>> _filterOptions = [
    {'value': 'semua', 'label': 'Semua Tempat'},
    {'value': 'skateshop', 'label': 'Skateshop'},
    {'value': 'sports', 'label': 'Toko Sport'},
    {'value': 'komunitas', 'label': 'Komunitas'},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _locationStatus = 'Mengecek izin lokasi...';
      });

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Izin lokasi ditolak';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Izin lokasi ditolak secara permanen';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _locationStatus = 'Mendapatkan lokasi...';
      });

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _locationStatus = 'Lokasi ditemukan';
      });
      _calculateDistances();
      _searchNearbyShops();

      NotificationService.showSuccess(
        'Lokasi Ditemukan',
        'Berhasil mendapatkan lokasi Anda. Mencari skateshop terdekat...',
      );
    } catch (e) {
      setState(() {
        _locationStatus = 'Gagal mendapatkan lokasi: ${e.toString()}';
        _isLoading = false;
      });

      NotificationService.showError(
        'Error Lokasi',
        'Gagal mendapatkan lokasi: ${e.toString()}',
      );
    }
  }

  Future<void> _searchNearbyShops() async {
    try {
      setState(() {
        _locationStatus = 'Mencari skateshop terdekat...';
      });

      double searchLat =
          _currentPosition?.latitude ?? -7.7956; // Default Yogyakarta
      double searchLng = _currentPosition?.longitude ?? 110.3695;

      final shops = await GooglePlacesService.searchSkateshopsNearYogyakarta(
        latitude: searchLat,
        longitude: searchLng,
        radius: 20000, // 20km radius
      );

      setState(() {
        _nearbyShops = shops;
        _locationStatus = 'Ditemukan ${shops.length} tempat';
        _isLoading = false;
      });

      _filterShops();
    } catch (e) {
      setState(() {
        _locationStatus = 'Gagal mencari skateshop: ${e.toString()}';
        _isLoading = false;
      });

      NotificationService.showError(
        'Error Pencarian',
        'Gagal mencari skateshop: ${e.toString()}',
      );
    }
  }

  void _calculateDistances() {
    if (_currentPosition == null || _nearbyShops.isEmpty) return;

    for (var shop in _nearbyShops) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        shop['latitude'],
        shop['longitude'],
      );
      shop['distance'] = distance / 1000; // Convert to kilometers
    }

    // Sort by distance
    _nearbyShops.sort((a, b) => a['distance'].compareTo(b['distance']));
  }

  void _filterShops() {
    setState(() {
      if (_selectedFilter == 'semua') {
        // Show all shops
      } else {
        _nearbyShops = _nearbyShops
            .where((shop) => shop['type'] == _selectedFilter)
            .toList();
      }
    });
  }

  void _onFilterChanged(String? newFilter) {
    setState(() {
      _selectedFilter = newFilter ?? 'semua';
    });
    _searchNearbyShops(); // Re-search with new filter
  }

  Future<void> _openMaps(double latitude, double longitude, String name) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      NotificationService.showError(
        'Error',
        'Tidak dapat membuka aplikasi maps',
      );
    }
  }

  Future<void> _callPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      NotificationService.showError(
        'Error',
        'Tidak dapat melakukan panggilan',
      );
    }
  }

  void _showRouteToShop(Map<String, dynamic> shop) {
    if (_currentPosition == null) {
      NotificationService.showError(
        'Error',
        'Lokasi Anda belum ditemukan',
      );
      return;
    }

    // Hitung bearing (arah) dari posisi current ke shop
    double bearing = _calculateBearing(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      shop['latitude'],
      shop['longitude'],
    );

    String direction = _bearingToDirection(bearing);
    double distance = shop['distance'] ?? 0;

    setState(() {
      _selectedShop = shop;
      _showRoute = true;
      _routeInfo = 'Jarak: ${distance.toStringAsFixed(2)} km\n'
          'Arah: $direction\n'
          'Estimasi waktu: ${_calculateTravelTime(distance)}';
    });

    NotificationService.showInfo(
      'Rute Ditemukan',
      'Rute ke ${shop['name']} telah ditampilkan',
    );
  }

  double _calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    double dLng = (lng2 - lng1) * (3.14159 / 180);
    double lat1Rad = lat1 * (3.14159 / 180);
    double lat2Rad = lat2 * (3.14159 / 180);

    double y = sin(dLng) * cos(lat2Rad);
    double x =
        cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLng);

    double bearing = atan2(y, x) * (180 / 3.14159);
    return (bearing + 360) % 360;
  }

  String _bearingToDirection(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'Utara';
    if (bearing >= 22.5 && bearing < 67.5) return 'Timur Laut';
    if (bearing >= 67.5 && bearing < 112.5) return 'Timur';
    if (bearing >= 112.5 && bearing < 157.5) return 'Tenggara';
    if (bearing >= 157.5 && bearing < 202.5) return 'Selatan';
    if (bearing >= 202.5 && bearing < 247.5) return 'Barat Daya';
    if (bearing >= 247.5 && bearing < 292.5) return 'Barat';
    if (bearing >= 292.5 && bearing < 337.5) return 'Barat Laut';
    return 'Tidak diketahui';
  }

  String _calculateTravelTime(double distanceKm) {
    // Asumsi kecepatan rata-rata 40 km/jam di dalam kota
    double timeHours = distanceKm / 40;
    int minutes = (timeHours * 60).round();

    if (minutes < 60) {
      return '$minutes menit';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '$hours jam $remainingMinutes menit';
    }
  }

  void _hideRoute() {
    setState(() {
      _selectedShop = null;
      _showRoute = false;
      _routeInfo = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Peta Skateshop'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Location Status
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _currentPosition != null
                          ? Icons.location_on
                          : Icons.location_off,
                      color:
                          _currentPosition != null ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationStatus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentPosition != null
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_currentPosition != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                    'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Filter
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: const Color.fromARGB(255, 33, 150, 243)),
                SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _filterOptions.map((filter) {
                      return DropdownMenuItem<String>(
                        value: filter['value'],
                        child: Text(filter['label']!),
                      );
                    }).toList(),
                    onChanged: _onFilterChanged,
                  ),
                ),
              ],
            ),
          ),

          // Results Info
          if (!_isLoading)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Ditemukan ${_nearbyShops.length} skateshop',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Route Information Display
          if (_showRoute && _selectedShop != null)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rute ke ${_selectedShop!['name']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _hideRoute,
                        icon: Icon(Icons.close, color: Colors.grey),
                        tooltip: 'Tutup Rute',
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Lokasi Anda',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 6),
                          child: Column(
                            children: List.generate(
                              3,
                              (index) => Container(
                                width: 2,
                                height: 8,
                                color: Colors.grey.shade400,
                                margin: EdgeInsets.symmetric(vertical: 2),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedShop!['name'],
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _routeInfo,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openMaps(
                            _selectedShop!['latitude'],
                            _selectedShop!['longitude'],
                            _selectedShop!['name'],
                          ),
                          icon: Icon(Icons.open_in_new, size: 18),
                          label: Text('Buka di Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callPhone(_selectedShop!['phone']),
                          icon: Icon(Icons.phone, size: 18),
                          label: Text('Telepon'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Shop List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _nearbyShops.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _nearbyShops.length,
                        itemBuilder: (context, index) {
                          return _buildShopCard(_nearbyShops[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Tidak ada skateshop ditemukan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Coba ubah filter atau refresh lokasi',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _getCurrentLocation,
            icon: Icon(Icons.refresh),
            label: Text('Refresh Lokasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder since data comes from OpenStreetMap
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              color: Colors.grey[200],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getShopIcon(shop['type']),
                    size: 48,
                    color: _getTypeColor(shop['type']),
                  ),
                  SizedBox(height: 8),
                  Text(
                    shop['type'].toString().toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and distance
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shop['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (shop['distance'] != null)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${shop['distance'].toStringAsFixed(1)} km',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 8),

                // Type and rating
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor(shop['type']),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        shop['type'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 2),
                        Text(
                          shop['rating'].toString(),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Description
                Text(
                  shop['description'],
                  style: TextStyle(color: Colors.grey[600]),
                ),

                SizedBox(height: 8),

                // Address
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop['address'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4),

                // Hours
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      shop['hours'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),

                SizedBox(height: 16), // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRouteToShop(shop),
                        icon: Icon(Icons.directions, size: 18),
                        label: Text('Lihat Rute'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _callPhone(shop['phone']),
                        icon: Icon(Icons.phone, size: 18),
                        label: Text('Telepon'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'skateshop':
        return Colors.orange;
      case 'sports':
        return Colors.blue;
      case 'komunitas':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getShopIcon(String type) {
    switch (type) {
      case 'skateshop':
        return Icons.skateboarding;
      case 'sports':
        return Icons.sports;
      case 'komunitas':
        return Icons.group;
      default:
        return Icons.store;
    }
  }
}
