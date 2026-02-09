import 'package:cloud_firestore/cloud_firestore.dart';

class Session {
  final String id;
  final String patientId;
  final String patientName; // Patient's display name
  final DateTime startTime;
  final Duration duration;
  final String status; // 'Completed', 'Active'
  final int peakHeartRate;

  Session({
    required this.id,
    required this.patientId,
    this.patientName = 'Unknown',
    required this.startTime,
    required this.duration,
    required this.status,
    required this.peakHeartRate,
  });
  factory Session.fromFirestore(Map<String, dynamic> data, String id) {
    return Session(
      id: id,
      patientId: data['patientId'] ?? 'Unknown',
      patientName: data['patientName'] ?? 'Unknown Patient',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      duration: Duration(minutes: data['durationMinutes'] ?? 0),
      status: data['status'] ?? 'Pending',
      peakHeartRate: data['peakHeartRate'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'startTime': Timestamp.fromDate(startTime),
      'durationMinutes': duration.inMinutes,
      'status': status,
      'peakHeartRate': peakHeartRate,
    };
  }
}
