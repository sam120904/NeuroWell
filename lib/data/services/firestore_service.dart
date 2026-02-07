import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Users Collection
  CollectionReference get usersCollection => _firestore.collection('users');

  // Patients Collection
  CollectionReference get patientsCollection => _firestore.collection('patients');

  // Sessions Collection
  CollectionReference get sessionsCollection => _firestore.collection('sessions');

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUserId == null) return null;
    final doc = await usersCollection.doc(currentUserId).get();
    return doc.data() as Map<String, dynamic>?;
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    await usersCollection.doc(currentUserId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add patient
  Future<String> addPatient(Map<String, dynamic> patientData) async {
    final docRef = await patientsCollection.add({
      ...patientData,
      'clinicianId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Get patients for current user
  Stream<QuerySnapshot> getPatientsStream() {
    return patientsCollection
        .where('clinicianId', isEqualTo: currentUserId)
        .snapshots();
  }

  // Get patient by ID
  Future<Map<String, dynamic>?> getPatient(String patientId) async {
    final doc = await patientsCollection.doc(patientId).get();
    return doc.data() as Map<String, dynamic>?;
  }

  // Update patient
  Future<void> updatePatient(String patientId, Map<String, dynamic> data) async {
    await patientsCollection.doc(patientId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete patient
  Future<void> deletePatient(String patientId) async {
    await patientsCollection.doc(patientId).delete();
  }

  // Add session
  Future<String> addSession(String patientId, Map<String, dynamic> sessionData) async {
    final docRef = await sessionsCollection.add({
      ...sessionData,
      'patientId': patientId,
      'clinicianId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Get sessions for patient
  Stream<QuerySnapshot> getSessionsStream(String patientId) {
    return sessionsCollection
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Save biosensor data
  Future<void> saveBiosensorData(String sessionId, Map<String, dynamic> data) async {
    await sessionsCollection.doc(sessionId).collection('biosensorData').add({
      ...data,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get biosensor data stream for session
  Stream<QuerySnapshot> getBiosensorDataStream(String sessionId) {
    return sessionsCollection
        .doc(sessionId)
        .collection('biosensorData')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Add patient note
  Future<void> addPatientNote(String patientId, String content) async {
    await patientsCollection.doc(patientId).collection('notes').add({
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUserId,
    });
  }

  // Get notes stream for patient
  Stream<QuerySnapshot> getPatientNotesStream(String patientId) {
    return patientsCollection
        .doc(patientId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
