import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service to poll Blynk cloud for device status and dummy data toggle
class BlynkService {
  static final BlynkService _instance = BlynkService._internal();
  factory BlynkService() => _instance;
  BlynkService._internal();

  final _statusController = StreamController<BlynkStatus>.broadcast();
  final _logController =
      StreamController<String>.broadcast(); // Debug log stream
  Timer? _pollTimer;
  BlynkStatus _lastStatus = BlynkStatus.loading;
  int _consecutiveFailures = 0;
  String _lastError = '';

  /// Stream of Blynk connection status
  Stream<BlynkStatus> get statusStream => _statusController.stream;
  Stream<String> get logStream => _logController.stream;

  /// Current status
  BlynkStatus get currentStatus => _lastStatus;
  String get lastError => _lastError;

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
    final timestamp = DateTime.now().toIso8601String().substring(
      11,
      23,
    ); // HH:mm:ss.mmm
    debugPrint('[BlynkService $timestamp] $message');
    _logController.add('$timestamp: $message');
  }

  int _pollSubscribers = 0; // Reference count for active listeners

  /// Auth token from .env
  String get _authToken => dotenv.env['BLYNK_AUTH_TOKEN'] ?? '';

  /// Start polling every 3 seconds (shared)
  void startPolling() {
    _pollSubscribers++;
    _log('startPolling called. Subscribers: $_pollSubscribers');

    // If already polling, just return (don't restart timer)
    if (_pollTimer != null) {
      // Ensure we emit the *current* status immediately to the new subscriber
      // so they don't see "loading" or nothing.
      if (_lastStatus != BlynkStatus.loading) {
        _statusController.add(_lastStatus);
      }
      return;
    }

    // Emit initial loading status only on fresh start
    _statusController.add(BlynkStatus.loading);
    _lastError = '';

    // Initial fetch
    _fetchStatus();

    // Poll every 3 seconds to avoid rate limiting (Blynk/CORS)
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchStatus();
    });
  }

  /// Check if IoT device hardware is connected
  Future<bool> _isHardwareConnected() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uri = Uri.parse(
        '$_baseUrl/isHardwareConnected?token=$_authToken&_t=$timestamp',
      );
      // _log('Checking hardware: $uri'); // excessive log

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = response.body.toLowerCase().trim();
        final isOnline = body == 'true';
        if (!isOnline) _log('Hardware check returned FALSE (Body: $body)');
        return isOnline;
      } else {
        _log(
          'Error checking hardware: ${response.statusCode} - ${response.body}',
        );
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
      final url = Uri.parse(
        '$_baseUrl/get?token=$_authToken&pin=D1&_t=$timestamp',
      );

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));

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
      final url = Uri.parse(
        '$_baseUrl/get?token=$_authToken&pin=D0&_t=$timestamp',
      );

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 5));

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

    try {
      // Execute all checks in parallel for better synchronization and speed
      final results = await Future.wait([
        _isHardwareConnected(),
        _isStressModeEnabled(),
        _isDummyDataEnabled(),
      ]);

      final isHardwareOnline = results[0];
      final isStress = results[1];
      final isNormal = results[2];

      // 1. Check Hardware Connection
      // Relaxed Logic: If ANY check says "true" (meaning we got a valid response), trust that connection.
      // But we still prioritize isHardwareConnected for the "offline" state if all are false.

      if (!isHardwareOnline) {
        // If hardware says offline, BUT we got data from D0 or D1, it means the API is working
        // and the device might just be reporting offline temporarily or wrongly.
        if (isStress || isNormal) {
          _log(
            'WARN: Hardware says offline, but Simulation pins are active. Marking ONLINE.',
          );
          // Do not return, continue to set status
        } else {
          _consecutiveFailures++;
          if (_consecutiveFailures >= 2) {
            if (_lastStatus != BlynkStatus.offline) {
              _log('Device is OFFLINE (Failures: $_consecutiveFailures)');
            }
            _updateStatus(BlynkStatus.offline);
          }
          return;
        }
      }

      // Reset failure count if successful
      if (_consecutiveFailures > 0) {
        _log(
          'Device re-connected or check passed after $_consecutiveFailures failures',
        );
      }
      _consecutiveFailures = 0;
      _lastError = ''; // Clear error

      // 2. Check Stress Mode (D1)
      if (isStress) {
        _updateStatus(BlynkStatus.simulationStress);
        return;
      }

      // 3. Check Normal Simulation (D0)
      if (isNormal) {
        _updateStatus(BlynkStatus.simulationNormal);
        return;
      }

      // 4. Device Online but D0/D1 OFF
      _updateStatus(BlynkStatus.onlineNoData);
    } catch (e) {
      _log('Error during grouped fetch: $e');
      _lastError = 'Group Fetch Error: $e';
      // On error, behave like offline failure to be safe
      _consecutiveFailures++;
    }
  }

  void _updateStatus(BlynkStatus newStatus) {
    if (_lastStatus != newStatus) {
      _log('Status changed: $_lastStatus -> $newStatus');
      _lastStatus = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// Stop polling (decrements ref count)
  void stopPolling() {
    if (_pollSubscribers > 0) {
      _pollSubscribers--;
      _log('stopPolling called. Subscribers remaining: $_pollSubscribers');
    }

    if (_pollSubscribers <= 0) {
      _pollSubscribers = 0; // Safety clamp
      if (_pollTimer != null) {
        _log('No subscribers left. Timer cancelled.');
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    }
  }

  void dispose() {
    _log('dispose called');
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
