import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      debugPrint('Gemini API Key not found in .env');
       // Handle error appropriately, maybe disable features or show a warning
    }
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey ?? '',
    );
  }

  Future<String> generateInsight(String patientData) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'Please configure GEMINI_API_KEY in .env file';
    }

    final content = [Content.text(patientData)];
    try {
      final response = await _model.generateContent(content);
      return response.text ?? 'No insight generated.';
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return 'Failed to generate insight: $e';
    }
  }

  Future<String> analyzeSession(Map<String, dynamic> biosensorData, String notes) async {
    final prompt = '''
      Analyze the following live biosensor data and therapist notes for a patient during a session.
      
      Biosensor Data:
      Heart Rate: ${biosensorData['heartRate']} bpm
      HRV: ${biosensorData['hrv']} ms
      GSR: ${biosensorData['gsr']} µS
      Oxygen Saturation: ${biosensorData['oxygenSaturation']}%
      
      Therapist Notes: "$notes"
      
      Provide a brief clinical insight (max 3 sentences) interpreting the physiological data in context of the notes. Focus on stress, relaxation, or potential anomalies.
    ''';
    return generateInsight(prompt);
  }

  Future<String> analyzePatientStress(Map<String, dynamic> biosensorData) async {
    final prompt = '''
      Analyze the following biosensor data for a patient and provide a brief clinical insight about their stress level:
      Heart Rate: ${biosensorData['heartRate']} bpm
      HRV: ${biosensorData['hrv']} ms
      GSR: ${biosensorData['gsr']} µS
      Oxygen Saturation: ${biosensorData['oxygenSaturation']}%
      
      Provide a 2-sentence summary for a clinician.
    ''';
    return generateInsight(prompt);
  }
}
