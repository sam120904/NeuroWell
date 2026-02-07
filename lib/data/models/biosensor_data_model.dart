class BiosensorData {
  final DateTime timestamp;
  final int heartRate;      // Heart Beat: Normal 60-100, Stress 100-140 BPM
  final int spo2;           // SpO2: Normal 95-100%, Stress 93-97%
  final double gsr;         // GSR: Galvanic Skin Response (µS)
  final List<double> ecgData; // ECG waveform data points for graph

  BiosensorData({
    required this.timestamp,
    required this.heartRate,
    required this.spo2,
    required this.gsr,
    required this.ecgData,
  });

  // Factory to create from Map (for Firebase)
  factory BiosensorData.fromMap(Map<String, dynamic> map) {
    return BiosensorData(
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      heartRate: map['heartRate'] ?? 0,
      spo2: map['spo2'] ?? 0,
      gsr: (map['gsr'] ?? 0).toDouble(),
      ecgData: (map['ecgData'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? [],
    );
  }
  
  /// Check if vitals indicate stress
  bool get isStressed => heartRate > 100 || spo2 < 95;
}
