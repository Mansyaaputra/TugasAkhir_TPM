import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import 'NotificationService.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // Accelerometer variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  List<double> _accelerometerValues = [0, 0, 0];

  // Step counter variables
  int _stepCount = 0;
  double _lastMagnitude = 0;
  bool _isStepDetected = false;

  // Shake detection variables
  DateTime? _lastShakeTime;
  static const double _shakeThreshold = 15.0;
  Function? _onShakeCallback;

  // Activity detection
  String _currentActivity = 'Diam';
  Function(String)? _onActivityChanged;

  // Getters
  List<double> get accelerometerValues => _accelerometerValues;
  int get stepCount => _stepCount;
  String get currentActivity => _currentActivity;

  // Initialize sensor services
  Future<void> initialize() async {
    await _startAccelerometerListening();
  }

  // Start listening to accelerometer
  Future<void> _startAccelerometerListening() async {
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        _accelerometerValues = [event.x, event.y, event.z];
        _detectSteps(event);
        _detectShake(event);
        _detectActivity(event);
      },
    );
  }

  // Step detection algorithm
  void _detectSteps(AccelerometerEvent event) {
    double magnitude =
        sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

    if (_lastMagnitude > 0) {
      double difference = (magnitude - _lastMagnitude).abs();

      if (difference > 2.0 && !_isStepDetected) {
        _stepCount++;
        _isStepDetected = true;

        // Reset detection flag after a short delay
        Future.delayed(Duration(milliseconds: 500), () {
          _isStepDetected = false;
        });
      }
    }

    _lastMagnitude = magnitude;
  }

  // Shake detection
  void _detectShake(AccelerometerEvent event) {
    double acceleration =
        sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

    if (acceleration > _shakeThreshold) {
      DateTime now = DateTime.now();

      if (_lastShakeTime == null ||
          now.difference(_lastShakeTime!).inMilliseconds > 1000) {
        _lastShakeTime = now;

        if (_onShakeCallback != null) {
          _onShakeCallback!();
        }

        NotificationService.showInfo(
          'Shake Detected!',
          'Refreshing data...',
        );
      }
    }
  }

  // Activity detection based on movement patterns
  void _detectActivity(AccelerometerEvent event) {
    double magnitude =
        sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
    String newActivity;

    if (magnitude < 1.5) {
      newActivity = 'Diam';
    } else if (magnitude < 5.0) {
      newActivity = 'Berjalan';
    } else if (magnitude < 8.0) {
      newActivity = 'Berlari';
    } else {
      newActivity = 'Skateboarding'; // High movement = likely skateboarding
    }

    if (newActivity != _currentActivity) {
      _currentActivity = newActivity;
      if (_onActivityChanged != null) {
        _onActivityChanged!(newActivity);
      }
    }
  }

  // Set shake callback
  void setShakeCallback(Function callback) {
    _onShakeCallback = callback;
  }

  // Set activity change callback
  void setActivityChangeCallback(Function(String) callback) {
    _onActivityChanged = callback;
  }

  // Reset step counter
  void resetStepCounter() {
    _stepCount = 0;
  }

  // Get movement intensity (for UI feedback)
  double getMovementIntensity() {
    double magnitude = sqrt(pow(_accelerometerValues[0], 2) +
        pow(_accelerometerValues[1], 2) +
        pow(_accelerometerValues[2], 2));
    return (magnitude / 10.0).clamp(0.0, 1.0);
  }

  // Dispose resources
  void dispose() {
    _accelerometerSubscription?.cancel();
  }

  // Get sensor status for UI
  Map<String, dynamic> getSensorStatus() {
    return {
      'isActive': _accelerometerSubscription != null,
      'stepCount': _stepCount,
      'activity': _currentActivity,
      'movementIntensity': getMovementIntensity(),
      'accelerometer': {
        'x': _accelerometerValues[0].toStringAsFixed(2),
        'y': _accelerometerValues[1].toStringAsFixed(2),
        'z': _accelerometerValues[2].toStringAsFixed(2),
      }
    };
  }
}
