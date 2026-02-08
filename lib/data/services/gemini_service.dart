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
  Future<String> generateSessionReport(String transcript, String duration, Map<String, dynamic> avgStats) async {
    final prompt = '''
      You are a clinical assistant generating a post-session report for a therapy session.
      
      Session Duration: $duration
      
      Average Physiological Stats:
      - Heart Rate: ${avgStats['avgHr']} bpm
      - SpO2: ${avgStats['avgSpo2']}%
      - Stress Events (High HR/Low SpO2): ${avgStats['stressEvents']}
      
      Full Session Transcript:
      "$transcript"
      
      Please provide a comprehensive report including:
      1. **Patient State Summary**: Based on physiological data (stress levels).
      2. **Key Topics Discussed**: Briefly summarize the main themes from the transcript.
      3. **Clinical Observations**: Correlate any stress markers with specific topics if possible (infer from context).
      4. **Recommendations**: Suggested next steps or focus areas for the next session.
      
      Format with clear Markdown headings.
    ''';
    return generateInsight(prompt);
  }
}
