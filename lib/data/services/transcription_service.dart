import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class TranscriptionService {
  final SpeechToText _speechToText = SpeechToText();
  final _transcriptionController = StreamController<String>.broadcast();
  bool _isListening = false;
  String _currentLocaleId = '';

  Stream<String> get transcriptionStream => _transcriptionController.stream;
  bool get isListening => _isListening;

  Future<bool> init() async {
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('[TranscriptionService] Microphone permission denied');
        return false;
      }

      bool available = await _speechToText.initialize(
        onError: (error) => debugPrint('[TranscriptionService] Error: $error'),
        onStatus: (status) => debugPrint('[TranscriptionService] Status: $status'),
      );

      if (available) {
        var systemLocale = await _speechToText.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }

      return available;
    } catch (e) {
      debugPrint('[TranscriptionService] Init error: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    if (!_speechToText.isAvailable) {
      bool initialized = await init();
      if (!initialized) return;
    }

    if (!_isListening) {
      _isListening = true;
      try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult || result.recognizedWords.isNotEmpty) {
            // debugPrint('[Transcription] Result: ${result.recognizedWords} (Final: ${result.finalResult})');
            _transcriptionController.add(result.recognizedWords);
          }
        },
        localeId: _currentLocaleId,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
      debugPrint('[TranscriptionService] Listening started');
      } catch (e) {
         debugPrint('[TranscriptionService] Start listening error: $e');
         _isListening = false;
      }
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  void dispose() {
    _transcriptionController.close();
  }
}
