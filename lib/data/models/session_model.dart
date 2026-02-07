import 'package:cloud_firestore/cloud_firestore.dart';

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
  factory Session.fromFirestore(Map<String, dynamic> data, String id) {
    return Session(
      id: id,
      patientId: data['patientId'] ?? 'Unknown',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      duration: Duration(minutes: data['durationMinutes'] ?? 0),
      status: data['status'] ?? 'Pending',
      peakHeartRate: data['peakHeartRate'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'startTime': Timestamp.fromDate(startTime),
      'durationMinutes': duration.inMinutes,
      'status': status,
      'peakHeartRate': peakHeartRate,
    };
  }
}
