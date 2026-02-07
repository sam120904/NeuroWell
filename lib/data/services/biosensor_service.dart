import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/biosensor_data_model.dart';

class BiosensorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _controller = StreamController<BiosensorData>.broadcast();
  StreamSubscription? _subscription;

  Stream<BiosensorData> get dataStream => _controller.stream;

  void startSimulation() {
    // Connect to Firestore "live" session
    try {
      _subscription = _firestore
          .collection('live_sessions')
          .doc('current')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          final sensorData = BiosensorData(
            timestamp: DateTime.now(), // Or parse from Firestore if available
            heartRate: data['heartRate'] ?? 0,
            oxygenSaturation: data['oxygenSaturation'] ?? 0,
            hrv: data['hrv'] ?? 0,
            gsr: data['gsr'] ?? 0,
          );
          _controller.add(sensorData);
        }
      }, onError: (error) {
        print('Error listening to sensor data: $error');
      });
    } catch (e) {
      print('Error starting sensor service: $e');
    }
  }

  void stopSimulation() {
    _subscription?.cancel();
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
