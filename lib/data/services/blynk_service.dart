import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service to poll Blynk cloud for device status and dummy data toggle
class BlynkService {
  static final BlynkService _instance = BlynkService._internal();
  factory BlynkService() => _instance;
  BlynkService._internal();

  final _statusController = StreamController<BlynkStatus>.broadcast();
  final _logController = StreamController<String>.broadcast(); // Debug log stream
  Timer? _pollTimer;
  BlynkStatus _lastStatus = BlynkStatus.loading;

  /// Stream of Blynk connection status
  Stream<BlynkStatus> get statusStream => _statusController.stream;
  Stream<String> get logStream => _logController.stream;
  
  /// Current status
  BlynkStatus get currentStatus => _lastStatus;

  /// Blynk API base URL
  /// Using CORS proxy for Web to avoid "Failed to fetch" / XMLHttpRequest error
  String get _baseUrl {
    const blynkUrl = 'https://blynk.cloud/external/api';
    if (kIsWeb) {
      return 'https://corsproxy.io/?$blynkUrl';
    }
    return blynkUrl;
  }
  
  void _log(String message) {
    if (kDebugMode) print('[BlynkService] $message');
    _logController.add('${DateTime.now().toIso8601String().substring(11, 19)}: $message');
  }
  
  /// Auth token from .env
  String get _authToken => dotenv.env['BLYNK_AUTH_TOKEN'] ?? '';

  /// Start polling every 1 second
  void startPolling() {
    if (kDebugMode) {
      print('[BlynkService] Starting polling with token: ${_authToken.isNotEmpty ? "***${_authToken.substring(_authToken.length - 4)}" : "EMPTY"}');
    }
    
    // Emit initial loading status
    _statusController.add(BlynkStatus.loading);
    
    // Initial fetch
    _fetchStatus();
    
    // Poll every 1 second
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _fetchStatus();
    });
  }

  /// Check if IoT device hardware is connected
  Future<bool> _isHardwareConnected() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('$_baseUrl/isHardwareConnected?token=$_authToken&_t=$timestamp'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final isOnline = response.body.toLowerCase() == 'true';
        _log('Hardware connected: $isOnline');
        return isOnline;
      } else {
        _log('Error checking hardware: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      _log('Exception checking hardware: $e');
      return false;
    }
  }

  /// Get V1 (Stress Mode) status
  Future<bool> _isStressModeEnabled() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = Uri.parse('$_baseUrl/get?token=$_authToken&pin=D1&_t=$timestamp');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith('[') && body.endsWith(']')) {
           return body.contains('1') || body.contains('true');
        }
        return body == '1' || body == 'true' || body == '"1"';
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Exception checking V1: $e');
      return false;
    }
  }

  /// Get V0 dummy data button status
  Future<bool> _isDummyDataEnabled() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = Uri.parse('$_baseUrl/get?token=$_authToken&pin=D0&_t=$timestamp');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.startsWith('[') && body.endsWith(']')) {
           return body.contains('1') || body.contains('true');
        }
        return body == '1' || body == 'true' || body == '"1"';
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Exception checking D0: $e');
      return false;
    }
  }

  /// Fetch complete status
  Future<void> _fetchStatus() async {
    if (_authToken.isEmpty) {
      _updateStatus(BlynkStatus.offline);
      return;
    }

    // 1. Check Hardware Connection FIRST
    // User Requirement: "when device is offline show it as offline"
    final isHardwareOnline = await _isHardwareConnected();
    
    if (!isHardwareOnline) {
      _updateStatus(BlynkStatus.offline);
      return;
    }

    // Device is ONLINE. Now check simulation pins (D1/D0)
    // User Requirement: "when device is ON and D1 is ON..."

    // 2. Check Stress Mode (D1)
    final isStress = await _isStressModeEnabled();
    if (isStress) {
      _updateStatus(BlynkStatus.simulationStress);
      return;
    }

    // 3. Check Normal Simulation (D0)
    final isNormal = await _isDummyDataEnabled();
    if (isNormal) {
      _updateStatus(BlynkStatus.simulationNormal);
      return; 
    }

    // 4. Device Online but D0/D1 OFF
    _updateStatus(BlynkStatus.onlineNoData);
  }

  void _updateStatus(BlynkStatus newStatus) {
    if (_lastStatus != newStatus) {
      _lastStatus = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// Stop polling
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void dispose() {
    stopPolling();
    _statusController.close();
  }
}

/// Blynk connection status enum
enum BlynkStatus {
  /// Hardware is offline/disconnected
  offline,
  /// Hardware is online but dummy data is OFF (show zeros)
  onlineNoData,
  /// Simulation: Normal Data (D0 ON, 60-100 BPM)
  simulationNormal,
  /// Simulation: Stress Data (D1 ON, 100-140 BPM)
  simulationStress,
  /// Initial connecting state
  loading,
}
