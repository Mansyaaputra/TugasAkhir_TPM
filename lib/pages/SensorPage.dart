import 'package:flutter/material.dart';
import '../services/SensorService.dart';
import '../services/NotificationService.dart';
import 'dart:async';

class SensorPage extends StatefulWidget {
  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> with TickerProviderStateMixin {
  final SensorService _sensorService = SensorService();
  Timer? _updateTimer;
  late AnimationController _pulseController;
  late AnimationController _shakeController;

  Map<String, dynamic> _sensorData = {};
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _initializeSensors();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    _sensorService.dispose();
    super.dispose();
  }

  void _initializeSensors() async {
    await _sensorService.initialize();

    // Setup callbacks
    _sensorService.setShakeCallback(() {
      _shakeController.forward().then((_) => _shakeController.reverse());
      _onShakeDetected();
    });

    _sensorService.setActivityChangeCallback((activity) {
      if (mounted) {
        NotificationService.showInfo(
          'Aktivitas Berubah',
          'Sekarang: $activity',
        );
      }
    });

    _startMonitoring();
  }

  void _startMonitoring() {
    setState(() => _isMonitoring = true);

    _updateTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _sensorData = _sensorService.getSensorStatus();
        });
      }
    });
  }

  void _stopMonitoring() {
    setState(() => _isMonitoring = false);
    _updateTimer?.cancel();
  }

  void _onShakeDetected() {
    // Implementasi shake to refresh
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 8),
            Text('Data di-refresh dengan shake!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor Skateboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isMonitoring
                                    ? Colors.green
                                        .withOpacity(_pulseController.value)
                                    : Colors.grey,
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 8),
                        Text(
                          _isMonitoring ? 'Sensor Aktif' : 'Sensor Tidak Aktif',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Goyangkan HP untuk refresh data',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Step Counter
            _buildStepCounter(),
            SizedBox(height: 16),

            // Activity Detection
            _buildActivityDetection(),
            SizedBox(height: 16),

            // Accelerometer Data
            _buildAccelerometerData(),
            SizedBox(height: 16),

            // Movement Visualization
            _buildMovementVisualization(),
            SizedBox(height: 16),

            // Skateboarding Tips
            _buildSkateboardingTips(),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_shakeController.value * 0.2),
            child: FloatingActionButton(
              onPressed: () {
                _sensorService.resetStepCounter();
                NotificationService.showSuccess(
                  'Reset',
                  'Step counter direset!',
                );
              },
              backgroundColor: Colors.orange,
              child: Icon(Icons.refresh),
              tooltip: 'Reset Step Counter',
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepCounter() {
    int steps = _sensorData['stepCount'] ?? 0;
    double distance = steps * 0.7; // Rata-rata 70cm per langkah

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Step Counter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$steps',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text('Langkah'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${distance.toStringAsFixed(1)}m',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text('Jarak'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityDetection() {
    String activity = _sensorData['activity'] ?? 'Unknown';
    Color activityColor;
    IconData activityIcon;

    switch (activity) {
      case 'Diam':
        activityColor = Colors.grey;
        activityIcon = Icons.airline_seat_recline_normal;
        break;
      case 'Berjalan':
        activityColor = Colors.blue;
        activityIcon = Icons.directions_walk;
        break;
      case 'Berlari':
        activityColor = Colors.orange;
        activityIcon = Icons.directions_run;
        break;
      case 'Skateboarding':
        activityColor = Colors.red;
        activityIcon = Icons.skateboarding;
        break;
      default:
        activityColor = Colors.grey;
        activityIcon = Icons.help;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Deteksi Aktivitas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: activityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: activityColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(activityIcon, color: activityColor, size: 32),
                  SizedBox(width: 12),
                  Text(
                    activity,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: activityColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccelerometerData() {
    Map<String, dynamic> accel = _sensorData['accelerometer'] ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Data Accelerometer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAxisData('X', accel['x'] ?? '0.00', Colors.red),
                _buildAxisData('Y', accel['y'] ?? '0.00', Colors.green),
                _buildAxisData('Z', accel['z'] ?? '0.00', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAxisData(String axis, String value, Color color) {
    return Column(
      children: [
        Text(
          axis,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text('m/s²'),
      ],
    );
  }

  Widget _buildMovementVisualization() {
    double intensity = _sensorData['movementIntensity'] ?? 0.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Intensitas Gerakan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: intensity,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(Colors.green, Colors.red, intensity)!,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${(intensity * 100).toStringAsFixed(1)}% intensitas',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkateboardingTips() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.yellow[700]),
                SizedBox(width: 8),
                Text(
                  'Tips Skateboarding',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Gunakan sensor untuk melacak progress latihan\n'
              '• Gerakan skating akan terdeteksi sebagai "Skateboarding"\n'
              '• Goyangkan HP untuk refresh data produk\n'
              '• Step counter membantu tracking jarak ke skateshop',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
