import 'dart:async';
import 'dart:math';
import '../models/biosensor_data_model.dart';

class BiosensorService {
  // Simulator for demo purposes
  // In real app, this would be:
  // final DatabaseReference _ref = FirebaseDatabase.instance.ref('sensors/esp32_01');

  final _controller = StreamController<BiosensorData>.broadcast();
  Timer? _timer;

  Stream<BiosensorData> get dataStream => _controller.stream;

  void startSimulation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final random = Random();
      
      // Simulate realistic fluctuations
      final data = BiosensorData(
        timestamp: now,
        heartRate: 70 + random.nextInt(10), // 70-80 BPM
        oxygenSaturation: 95 + random.nextInt(4), // 95-99%
        hrv: 50 + random.nextInt(20), // 50-70 ms
        gsr: 200 + random.nextInt(50), // 200-250 µS
      );
      
      _controller.add(data);
    });
  }

  void stopSimulation() {
    _timer?.cancel();
  }

  void dispose() {
     _timer?.cancel();
    _controller.close();
  }
}
