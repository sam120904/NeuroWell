class Session {
  final String id;
  final String patientId;
  final DateTime startTime;
  final Duration duration;
  final String status; // 'Completed', 'Active'
  final int peakHeartRate;

  Session({
    required this.id,
    required this.patientId,
    required this.startTime,
    required this.duration,
    required this.status,
    required this.peakHeartRate,
  });
}
