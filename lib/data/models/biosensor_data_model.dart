class BiosensorData {
  final DateTime timestamp;
  final int heartRate;
  final int oxygenSaturation;
  final int hrv;
  final int gsr;

  BiosensorData({
    required this.timestamp,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.hrv,
    required this.gsr,
  });

  // Factory to create from Map (for Firebase)
  factory BiosensorData.fromMap(Map<String, dynamic> map) {
    return BiosensorData(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      heartRate: map['heartRate'] ?? 0,
      oxygenSaturation: map['oxygenSaturation'] ?? 0,
      hrv: map['hrv'] ?? 0,
      gsr: map['gsr'] ?? 0,
    );
  }
}
