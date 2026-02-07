import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  // TODO: Replace with your actual API key
  // Recommended: Use --dart-define=GEMINI_API_KEY=... at build time
  static const String _apiKey = 'AIzaSyB_e38TcWai7Idql_uckwIF91jyqMU5T2Y';
  
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> generateInsight(String patientData) async {
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      return 'Please configure your Gemini API Key in lib/data/services/gemini_service.dart';
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
