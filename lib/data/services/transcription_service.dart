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
  bool get isAvailable => _speechToText.isAvailable;
  
  // Expose error stream
  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorController.stream;

  // Expose listening state
  final _listeningStateController = StreamController<bool>.broadcast();
  Stream<bool> get listeningStateStream => _listeningStateController.stream;

  Future<bool> init() async {
    try {
      // On web, permission is handled by browser on initialize/listen
      if (!kIsWeb) {
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          debugPrint('[TranscriptionService] Microphone permission denied');
          _errorController.add('Microphone permission denied');
          return false;
        }
      }

      bool available = await _speechToText.initialize(
        onError: (error) {
          debugPrint('[TranscriptionService] Error: $error');
          _errorController.add(error.errorMsg);
          _isListening = false;
          _listeningStateController.add(false);
        },
        onStatus: (status) {
          debugPrint('[TranscriptionService] Status: $status');
          bool listening = status == 'listening';
          if (_isListening != listening) {
             _isListening = listening;
             _listeningStateController.add(listening);
          }
          if (status == 'done' || status == 'notListening') {
             _isListening = false;
             _listeningStateController.add(false);
          }
        },
      );
      
      // ... (rest of init)
      
      if (available) {
        var systemLocale = await _speechToText.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }

      return available;
    } catch (e) {
      debugPrint('[TranscriptionService] Init error: $e');
      _errorController.add('Init error: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    // ... (rest of startListening)
    if (!_isListening) {
      try {
        await _speechToText.listen(
          // ... options
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty) {
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
        _isListening = true;
        _listeningStateController.add(true);
        debugPrint('[TranscriptionService] Listening started');
      } catch (e) {
         debugPrint('[TranscriptionService] Start listening error: $e');
         _errorController.add('Start listening failed: $e');
         _isListening = false;
         _listeningStateController.add(false);
      }
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      _listeningStateController.add(false);
    }
  }

  void dispose() {
    _transcriptionController.close();
    _errorController.close();
    _listeningStateController.close();
  }
}

