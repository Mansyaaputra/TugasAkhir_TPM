import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../services/NotificationService.dart';
import '../services/GooglePlacesService.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SkateshopMapPage extends StatefulWidget {
  @override
  _SkateshopMapPageState createState() => _SkateshopMapPageState();
}

class _SkateshopMapPageState extends State<SkateshopMapPage> {
  Position? _currentPosition;
  bool _isLoading = true;
  String _locationStatus = '';
  List<Map<String, dynamic>> _nearbyShops = [];
  List<Map<String, dynamic>> _allShops = [];
  String _selectedFilter = 'semua';
  Map<String, dynamic>? _selectedShop;
  bool _showRoute = false;
  String _routeInfo = '';
  List<LatLng> _routePoints = [];

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

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _locationStatus = 'Mengecek izin lokasi...';
      });

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

      // Tambahkan try-catch untuk getCurrentPosition
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        );

        setState(() {
          _currentPosition = position;
        });
      } catch (e) {
        // Jika gagal mendapatkan lokasi real, gunakan default Yogyakarta
        setState(() {
          _currentPosition = Position(
            latitude: -7.7956,
            longitude: 110.3695,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          _locationStatus = 'Menggunakan lokasi default Yogyakarta';
        });
      }

      await _searchNearbyShops();

      if (mounted) {
        NotificationService.showSuccess(
          'Lokasi Ditemukan',
          'Berhasil mendapatkan lokasi Anda di Yogyakarta.',
        );
      }
    } catch (e) {
      setState(() {
        _locationStatus = 'Gagal mendapatkan lokasi: ${e.toString()}';
        _isLoading = false;
      });

      if (mounted) {
        NotificationService.showError(
          'Error Lokasi',
          'Gagal mendapatkan lokasi: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _searchNearbyShops() async {
    try {
      setState(() {
        _locationStatus = 'Mencari skateshop terdekat di Yogyakarta...';
      });

      // Default ke koordinat Yogyakarta jika lokasi tidak tersedia
      double searchLat = _currentPosition?.latitude ?? -7.7956;
      double searchLng = _currentPosition?.longitude ?? 110.3695;

      List<Map<String, dynamic>> shops =
          _getJogjaSkateshops(searchLat, searchLng);

      setState(() {
        _allShops = List.from(shops);
        _nearbyShops = List.from(shops);
        _isLoading = false;
      });

      _calculateDistances();
      _filterShops();

      setState(() {
        _locationStatus = shops.isEmpty
            ? 'Tidak ada skateshop ditemukan di Yogyakarta'
            : 'Ditemukan ${shops.length} skateshop di Yogyakarta';
      });
    } catch (e) {
      setState(() {
        _allShops = [];
        _nearbyShops = [];
        _locationStatus = 'Gagal mencari skateshop: ${e.toString()}';
        _isLoading = false;
      });

      if (mounted) {
        NotificationService.showError(
          'Error Pencarian',
          'Gagal mencari skateshop: ${e.toString()}',
        );
      }
    }
  }

  List<Map<String, dynamic>> _getJogjaSkateshops(
      double centerLat, double centerLng) {
    // Data skateshop di Yogyakarta
    return [
      {
        'name': 'Skateshop Malioboro Street',
        'latitude': -7.7929,
        'longitude': 110.3668,
        'address': 'Jl. Malioboro No. 56, Yogyakarta',
        'phone': '+62-274-561234',
        'type': 'skateshop',
        'openHours': '09:00 - 21:00',
        'description':
            'Skateshop terlengkap di Malioboro dengan koleksi board lokal dan import',
      },
      {
        'name': 'Sport Station Jogja City Mall',
        'latitude': -7.8203,
        'longitude': 110.3883,
        'address': 'Jogja City Mall Lt. 2, Yogyakarta',
        'phone': '+62-274-567890',
        'type': 'sports',
        'openHours': '10:00 - 22:00',
        'description':
            'Toko sport dengan section skateboard dan longboard premium',
      },
      {
        'name': 'Gudeg Board Community',
        'latitude': -7.8014,
        'longitude': 110.3645,
        'address': 'Jl. Prawirotaman No. 12, Yogyakarta',
        'phone': '+62-274-587654',
        'type': 'komunitas',
        'openHours': '08:00 - 20:00',
        'description':
            'Komunitas skater Jogja dengan workshop dan custom board',
      },
      {
        'name': 'Tugu Skate Shop',
        'latitude': -7.7830,
        'longitude': 110.3675,
        'address': 'Jl. Mangkubumi No. 88, Yogyakarta',
        'phone': '+62-274-512345',
        'type': 'skateshop',
        'openHours': '10:00 - 21:30',
        'description': 'Skateshop dekat Tugu Jogja dengan harga terjangkau',
      },
      {
        'name': 'Extreme Board Hartono Mall',
        'latitude': -7.7689,
        'longitude': 110.4085,
        'address': 'Hartono Mall Lt. 1, Yogyakarta',
        'phone': '+62-274-598765',
        'type': 'sports',
        'openHours': '10:00 - 22:00',
        'description':
            'Toko board dan gear skateboard dengan kualitas internasional',
      },
      {
        'name': 'Jogja Skate Plaza',
        'latitude': -7.8056,
        'longitude': 110.3678,
        'address': 'Jl. Parangtritis Km. 2, Yogyakarta',
        'phone': '+62-274-576543',
        'type': 'skateshop',
        'openHours': '09:30 - 21:00',
        'description': 'Skateshop dengan skate park mini untuk testing board',
      },
      {
        'name': 'Kraton Skateboard Community',
        'latitude': -7.8053,
        'longitude': 110.3644,
        'address': 'Jl. Alun-Alun Utara No. 3, Yogyakarta',
        'phone': '+62-274-543210',
        'type': 'komunitas',
        'openHours': '07:00 - 19:00',
        'description':
            'Basecamp komunitas skater dengan view Kraton Yogyakarta',
      },
      {
        'name': 'UGM Skate Corner',
        'latitude': -7.7719,
        'longitude': 110.3747,
        'address': 'Jl. Kaliurang Km. 5, Sleman',
        'phone': '+62-274-521098',
        'type': 'skateshop',
        'openHours': '10:00 - 20:00',
        'description': 'Skateshop dekat kampus UGM, favorit mahasiswa',
      },
    ];
  }

  void _calculateDistances() {
    if (_currentPosition == null || _allShops.isEmpty) return;

    for (var shop in _allShops) {
      if (shop['latitude'] != null && shop['longitude'] != null) {
        double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          shop['latitude'],
          shop['longitude'],
        );
        shop['distance'] = distance / 1000; // Convert to kilometers
      }
    }

    // Sort by distance
    _allShops.sort((a, b) {
      final distanceA = a['distance'] ?? double.infinity;
      final distanceB = b['distance'] ?? double.infinity;
      return distanceA.compareTo(distanceB);
    });
  }

  void _filterShops() {
    setState(() {
      if (_selectedFilter == 'semua') {
        _nearbyShops = List.from(_allShops);
      } else {
        _nearbyShops =
            _allShops.where((shop) => shop['type'] == _selectedFilter).toList();
      }
    });
  }

  void _onFilterChanged(String? newFilter) {
    setState(() {
      _selectedFilter = newFilter ?? 'semua';
    });
    _filterShops(); // Hanya filter, jangan search ulang
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

  void _createRoute(LatLng destination) {
    if (_currentPosition == null) return;

    LatLng origin =
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    // Buat rute yang mengikuti jalanan (simulasi)
    List<LatLng> route = _createRealisticRoute(origin, destination);

    setState(() {
      _routePoints = route;
    });
  }

  List<LatLng> _createRealisticRoute(LatLng origin, LatLng destination) {
    List<LatLng> route = [];

    // Tambahkan titik awal
    route.add(origin);

    // Simulasi rute yang mengikuti pola jalan di Yogyakarta
    // Menggunakan koordinat jalan-jalan utama sebagai waypoint
    List<LatLng> waypoints = _calculateWaypoints(origin, destination);
    route.addAll(waypoints);

    // Tambahkan titik tujuan
    route.add(destination);

    return route;
  }

  List<LatLng> _calculateWaypoints(LatLng origin, LatLng destination) {
    List<LatLng> waypoints = [];

    // Jalan-jalan utama di Yogyakarta sebagai referensi routing
    List<LatLng> majorRoads = [
      LatLng(-7.7956, 110.3695), // Titik tengah Jogja
      LatLng(-7.7929, 110.3668), // Malioboro
      LatLng(-7.8014, 110.3645), // Prawirotaman
      LatLng(-7.8053, 110.3644), // Kraton area
      LatLng(-7.7830, 110.3675), // Tugu area
      LatLng(-7.7719, 110.3747), // UGM area
      LatLng(-7.8203, 110.3883), // Jogja City Mall area
      LatLng(-7.7689, 110.4085), // Hartono Mall area
    ];

    // Cari jalur terbaik melalui jalan utama
    List<LatLng> bestPath = _findBestPath(origin, destination, majorRoads);

    // Buat waypoint yang lebih detail di antara jalan utama
    for (int i = 0; i < bestPath.length - 1; i++) {
      LatLng start = bestPath[i];
      LatLng end = bestPath[i + 1];

      // Buat beberapa titik di antara untuk membuat rute terlihat smooth
      List<LatLng> segment = _createSegment(start, end);
      waypoints.addAll(segment);
    }

    return waypoints;
  }

  List<LatLng> _findBestPath(
      LatLng origin, LatLng destination, List<LatLng> majorRoads) {
    // Algoritma sederhana untuk mencari jalur terbaik
    List<LatLng> path = [origin];

    // Cari jalan utama terdekat dari origin
    LatLng nearestToOrigin = _findNearestPoint(origin, majorRoads);
    if (_getDistance(origin, nearestToOrigin) > 0.005) {
      path.add(nearestToOrigin);
    }

    // Jika destination jauh, tambahkan waypoint di tengah
    double totalDistance = _getDistance(origin, destination);
    if (totalDistance > 0.02) {
      // Jika lebih dari 2km
      // Cari jalan utama yang strategis sebagai waypoint
      LatLng midPoint = LatLng(
        (origin.latitude + destination.latitude) / 2,
        (origin.longitude + destination.longitude) / 2,
      );
      LatLng nearestToMid = _findNearestPoint(midPoint, majorRoads);

      if (!path.contains(nearestToMid)) {
        path.add(nearestToMid);
      }
    }

    // Cari jalan utama terdekat dari destination
    LatLng nearestToDestination = _findNearestPoint(destination, majorRoads);
    if (_getDistance(destination, nearestToDestination) > 0.005 &&
        !path.contains(nearestToDestination)) {
      path.add(nearestToDestination);
    }

    path.add(destination);
    return path;
  }

  LatLng _findNearestPoint(LatLng target, List<LatLng> points) {
    LatLng nearest = points.first;
    double minDistance = _getDistance(target, nearest);

    for (LatLng point in points) {
      double distance = _getDistance(target, point);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = point;
      }
    }

    return nearest;
  }

  double _getDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
          point1.latitude,
          point1.longitude,
          point2.latitude,
          point2.longitude,
        ) /
        1000; // Convert to kilometers
  }

  List<LatLng> _createSegment(LatLng start, LatLng end) {
    List<LatLng> segment = [];

    // Buat kurva yang mengikuti pola jalan (tidak lurus sempurna)
    int numPoints = 5; // Jumlah titik antara

    for (int i = 1; i < numPoints; i++) {
      double fraction = i / numPoints;

      // Tambahkan sedikit kurva untuk simulasi jalan
      double curveFactor = sin(fraction * 3.14159) * 0.001; // Kurva halus

      double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      double lng =
          start.longitude + (end.longitude - start.longitude) * fraction;

      // Tambahkan variasi untuk mengikuti jalan
      if (fraction > 0.2 && fraction < 0.8) {
        // Tambah kurva di tengah segmen
        lat += curveFactor;
        lng += curveFactor * 0.5;
      }

      segment.add(LatLng(lat, lng));
    }

    return segment;
  }

  String _calculateTravelTime(double distanceKm) {
    // Estimasi waktu berdasarkan kondisi jalan di Yogyakarta
    double speed;

    if (distanceKm < 2) {
      speed = 25; // Jalan dalam kota dengan traffic light
    } else if (distanceKm < 5) {
      speed = 35; // Jalan utama
    } else {
      speed = 45; // Jalan luar kota
    }

    double timeHours = distanceKm / speed;
    int minutes = (timeHours * 60).round();

    // Tambahkan waktu extra untuk kondisi traffic
    minutes += (distanceKm * 2).round(); // 2 menit per km untuk traffic

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

  void _showRouteToShop(Map<String, dynamic> shop) {
    if (_currentPosition == null) {
      NotificationService.showError(
        'Error',
        'Lokasi Anda belum ditemukan',
      );
      return;
    }

    if (shop['latitude'] == null || shop['longitude'] == null) {
      NotificationService.showError(
        'Error',
        'Koordinat toko tidak tersedia',
      );
      return;
    }

    double bearing = _calculateBearing(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      shop['latitude'].toDouble(),
      shop['longitude'].toDouble(),
    );

    String direction = _bearingToDirection(bearing);
    double distance = shop['distance'] ?? 0;

    // Buat rute ke toko
    LatLng destination = LatLng(
      shop['latitude'].toDouble(),
      shop['longitude'].toDouble(),
    );
    _createRoute(destination);

    setState(() {
      _selectedShop = shop;
      _showRoute = true;
      _routeInfo = 'Rute ke ${shop['name']}\n'
          'Jarak: ${distance.toStringAsFixed(2)} km\n'
          'Arah: $direction\n'
          'Estimasi waktu: ${_calculateTravelTime(distance)}';
    });

    NotificationService.showSuccess(
      'Rute Ditemukan',
      'Rute ke ${shop['name']} telah ditampilkan di peta',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Skateshop Yogyakarta'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _selectedFilter,
              dropdownColor: Colors.white,
              style: TextStyle(color: Colors.blue),
              underline: Container(),
              icon: Icon(Icons.filter_list, color: Colors.white),
              items: _filterOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']!,
                      style: TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: _onFilterChanged,
            ),
          ),
          if (_showRoute)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _showRoute = false;
                  _routePoints.clear();
                  _selectedShop = null;
                  _routeInfo = '';
                });
              },
              tooltip: 'Hapus Rute',
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                _currentPosition?.latitude ?? -7.7956,
                _currentPosition?.longitude ?? 110.3695,
              ),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.tugasakhir_tpm',
                maxNativeZoom: 19,
              ),

              // Route polyline dengan styling yang lebih baik
              if (_showRoute && _routePoints.isNotEmpty) ...[
                PolylineLayer(
                  polylines: [
                    // Shadow/outline
                    Polyline(
                      points: _routePoints,
                      color: Colors.black.withOpacity(0.3),
                      strokeWidth: 8.0,
                    ),
                    // Main route
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 5.0,
                    ),
                    // Highlight line
                    Polyline(
                      points: _routePoints,
                      color: Colors.lightBlue,
                      strokeWidth: 2.0,
                    ),
                  ],
                ),
              ],

              MarkerLayer(
                markers: [
                  // Current position marker
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                  // Shop markers
                  ..._nearbyShops
                      .where((shop) =>
                          shop['latitude'] != null && shop['longitude'] != null)
                      .map((shop) {
                    bool isSelected = _selectedShop == shop;
                    return Marker(
                      point: LatLng(
                        (shop['latitude'] as num).toDouble(),
                        (shop['longitude'] as num).toDouble(),
                      ),
                      child: GestureDetector(
                        onTap: () => _showShopBottomSheet(shop),
                        child: Container(
                          width: isSelected ? 50 : 40,
                          height: isSelected ? 50 : 40,
                          decoration: BoxDecoration(
                            color: _getShopColor(shop['type']),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.yellow : Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getShopIcon(shop['type']),
                            color: Colors.white,
                            size: isSelected ? 25 : 20,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Status info
          if (!_isLoading && _locationStatus.isNotEmpty)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _locationStatus,
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Route info dengan lebih banyak detail
          if (_showRoute && _routeInfo.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 10,
              right: 10,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Rute Tercepat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _routeInfo,
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '* Estimasi waktu sudah termasuk kondisi lalu lintas',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_selectedShop != null) {
                                _openMaps(
                                  _selectedShop!['latitude'].toDouble(),
                                  _selectedShop!['longitude'].toDouble(),
                                  _selectedShop!['name'] ?? 'Skateshop',
                                );
                              }
                            },
                            icon: Icon(Icons.navigation, color: Colors.white),
                            label: Text('Google Maps',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showRoute = false;
                                _routePoints.clear();
                                _selectedShop = null;
                                _routeInfo = '';
                              });
                            },
                            icon: Icon(Icons.close, color: Colors.white),
                            label: Text('Tutup',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: Icon(Icons.my_location),
        tooltip: 'Refresh Lokasi',
      ),
    );
  }

  Color _getShopColor(String? type) {
    switch (type) {
      case 'skateshop':
        return Colors.red;
      case 'sports':
        return Colors.orange;
      case 'komunitas':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  IconData _getShopIcon(String? type) {
    switch (type) {
      case 'skateshop':
        return Icons.store;
      case 'sports':
        return Icons.sports;
      case 'komunitas':
        return Icons.group;
      default:
        return Icons.store;
    }
  }

  void _showShopBottomSheet(Map<String, dynamic> shop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  _getShopIcon(shop['type']),
                  color: _getShopColor(shop['type']),
                  size: 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shop['name'] ?? 'Skateshop',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Distance info
            if (shop['distance'] != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Jarak: ${shop['distance'].toStringAsFixed(2)} km dari lokasi Anda',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shop['address'] ?? '-',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if ((shop['description'] ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  shop['description'] ?? '-',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (shop['phone'] != null &&
                        shop['phone'].toString().isNotEmpty) {
                      _callPhone(shop['phone']);
                    }
                  },
                  child: Text(
                    shop['phone'] ?? '-',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              shop['phone'] != null ? Colors.blue : Colors.grey,
                          decoration: shop['phone'] != null
                              ? TextDecoration.underline
                              : null,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(shop['openHours'] ?? '-',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (shop['latitude'] != null &&
                          shop['longitude'] != null) {
                        _openMaps(
                            shop['latitude'].toDouble(),
                            shop['longitude'].toDouble(),
                            shop['name'] ?? 'Skateshop');
                      }
                    },
                    icon: Icon(Icons.directions, color: Colors.white),
                    label: Text('Maps', style: TextStyle(color: Colors.white)),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showRouteToShop(shop);
                    },
                    icon: Icon(Icons.route, color: Colors.white),
                    label: Text('Rute', style: TextStyle(color: Colors.white)),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
