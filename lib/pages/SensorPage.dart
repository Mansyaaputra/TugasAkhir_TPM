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
    try {
      await _sensorService.initialize();

      // Setup callbacks
      _sensorService.setShakeCallback(() {
        _shakeController.forward().then((_) => _shakeController.reverse());
        _onShakeDetected();
      });

      _startMonitoring();
    } catch (e) {
      print('Error initializing sensors: $e');
    }
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

  void _onShakeDetected() {
    // Implementasi shake to refresh tanpa dummy action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 8),
            Text('Shake terdeteksi!'),
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
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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

            // Step Counter dan Sensor Data
            _buildStepCounter(),
            SizedBox(height: 16),

            // Tambahkan sensor data lainnya
            _buildSensorData(),
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

    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
            Center(
              child: Text(
                '$steps',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            Center(child: Text('Langkah')),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorData() {
    return Card(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Data Sensor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildSensorItem('Accelerometer X',
                (_sensorData['accelerometerX'] ?? 0.0).toStringAsFixed(2)),
            _buildSensorItem('Accelerometer Y',
                (_sensorData['accelerometerY'] ?? 0.0).toStringAsFixed(2)),
            _buildSensorItem('Accelerometer Z',
                (_sensorData['accelerometerZ'] ?? 0.0).toStringAsFixed(2)),
            _buildSensorItem('Shake Detected',
                (_sensorData['shakeDetected'] ?? false) ? 'Ya' : 'Tidak'),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
