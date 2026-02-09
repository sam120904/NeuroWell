import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import 'widgets/telemetry_card.dart';
import 'widgets/telemetry_chart.dart';
import '../../data/services/biosensor_service.dart';
import '../../data/services/blynk_service.dart';
import 'package:provider/provider.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/biosensor_data_model.dart';
import '../../data/models/patient_model.dart';
import '../../data/services/transcription_service.dart';

class LiveMonitoringView extends StatefulWidget {
  const LiveMonitoringView({super.key});

  @override
  State<LiveMonitoringView> createState() => _LiveMonitoringViewState();
}

class _LiveMonitoringViewState extends State<LiveMonitoringView> {
  final BiosensorService _service = BiosensorService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final TextEditingController _notesController = TextEditingController();

  String? _aiInsight;
  bool _isGeneratingInsight = false;
  bool _isSessionActive = false;
  String _transcription = '';
<<<<<<< HEAD
  Patient? _selectedPatient; // Currently selected patient for this session
  
=======

>>>>>>> 4c923598cbcf60d7f4e3c82d1179b9a418f99261
  // Timer State
  Timer? _sessionTimer;
  Timer? _insightTimer; // Auto-generate insights periodically
  StreamSubscription? _dataSubscription;
  Duration _sessionDuration = Duration.zero;
  final List<Map<String, dynamic>> _sessionTimelineData =
      []; // Store session data points

  @override
  void initState() {
    super.initState();
    debugPrint('[LiveView] initState');
    _transcriptionService.transcriptionStream.listen((text) {
      if (mounted) {
        setState(() {
          _transcription = text;
        });
      }
    });
  }

  @override
  void dispose() {
    debugPrint('[LiveView] dispose');
    _service.stopSimulation();
    _transcriptionService.dispose();
    _sessionTimer?.cancel();
    _insightTimer?.cancel();
    _dataSubscription?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleSession() async {
    if (_isSessionActive) {
      // Logic when turning OFF
      _sessionTimer?.cancel();
      _insightTimer?.cancel();
      _dataSubscription?.cancel();
      _service.stopSimulation();
      await _transcriptionService.stopListening();

      if (mounted) {
        setState(() => _isSessionActive = false);
        _showSessionSummary();
      }
    } else {
      // Show patient selection dialog FIRST
      final selectedPatient = await _showPatientSelectionDialog();
      if (selectedPatient == null) return; // User cancelled
      
      setState(() {
        _selectedPatient = selectedPatient;
        _isSessionActive = true;
        _sessionDuration = Duration.zero;
        _transcription = ''; // Clear previous transcript
        _aiInsight = null;
        _sessionTimelineData.clear(); // Clear old data
      });

      // Timer purely for UI display of duration
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _sessionDuration += const Duration(seconds: 1);
          });
        }
      });

      // Separate subscription for data collection
      _dataSubscription = _service.dataStream.listen((data) {
        if (data != null) {
          _sessionTimelineData.add({
            'timestamp': _formatDuration(_sessionDuration),
            'heartRate': data.heartRate,
            'spo2': data.spo2,
            'gsr': data.gsr,
            'isStressed': data.isStressed,
          });
        }
      });

      // Auto-generate insights every 15 seconds
      _insightTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        if (mounted && _isSessionActive && !_isGeneratingInsight) {
          _autoGenerateInsight();
        }
      });

      _service.startSimulation();
      // Transcription is now optional - controlled by toggle button
    }
  }
<<<<<<< HEAD
  
  /// Show patient selection dialog and return selected patient
  Future<Patient?> _showPatientSelectionDialog() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    return showDialog<Patient>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_search, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text('Select Patient', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx, null),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose which patient will be monitored in this session',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              
              // Patient List
              SizedBox(
                height: 300,
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestoreService.getPatientsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('No patients found', style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            Text('Add patients from the Patients tab first', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      );
                    }
                    
                    final patients = snapshot.data!.docs.map((doc) {
                      return Patient.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                    }).toList();
                    
                    return ListView.separated(
                      itemCount: patients.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${patient.age} yrs • ${patient.condition}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: patient.status == 'Active' ? Colors.green[50] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              patient.status,
                              style: TextStyle(
                                fontSize: 11,
                                color: patient.status == 'Active' ? Colors.green[700] : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          onTap: () => Navigator.pop(ctx, patient),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
=======

>>>>>>> 4c923598cbcf60d7f4e3c82d1179b9a418f99261
  /// Toggle transcription recording on/off
  void _toggleRecording() async {
    if (_transcriptionService.isListening) {
      await _transcriptionService.stopListening();
    } else {
      await _transcriptionService.startListening();
    }
    if (mounted) setState(() {});
  }

  void _showSessionSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SessionSummaryDialog(
        transcript: _transcription,
        duration: _formatDuration(_sessionDuration),
        timelineData: List.from(_sessionTimelineData), // Pass copy of data
        patientId: _selectedPatient?.id ?? 'general',
        patientName: _selectedPatient?.name ?? 'Unknown Patient',
        // Placeholder stats - in real app, calculate these from session data
        avgStats: {
<<<<<<< HEAD
          'avgHr': _sessionTimelineData.isEmpty ? 0 : (_sessionTimelineData.map((e) => e['heartRate'] as int).reduce((a, b) => a + b) / _sessionTimelineData.length).toStringAsFixed(0),
          'avgSpo2': _sessionTimelineData.isEmpty ? 0 : (_sessionTimelineData.map((e) => e['spo2'] as int).reduce((a, b) => a + b) / _sessionTimelineData.length).toStringAsFixed(0),
          'avgGsr': _sessionTimelineData.isEmpty ? 0 : (_sessionTimelineData.map((e) => e['gsr'] as double).reduce((a, b) => a + b) / _sessionTimelineData.length).toStringAsFixed(1),
          'stressEvents': _sessionTimelineData.where((e) => e['isStressed'] == true).length,
=======
          'avgHr': _sessionTimelineData.isEmpty
              ? 0
              : (_sessionTimelineData
                            .map((e) => e['heartRate'] as int)
                            .reduce((a, b) => a + b) /
                        _sessionTimelineData.length)
                    .toStringAsFixed(0),
          'avgSpo2': _sessionTimelineData.isEmpty
              ? 0
              : (_sessionTimelineData
                            .map((e) => e['spo2'] as int)
                            .reduce((a, b) => a + b) /
                        _sessionTimelineData.length)
                    .toStringAsFixed(0),
          'stressEvents': _sessionTimelineData
              .where((e) => e['isStressed'] == true)
              .length,
>>>>>>> 4c923598cbcf60d7f4e3c82d1179b9a418f99261
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    if (!_isSessionActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Live Monitoring Stopped',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a session to connect to the biosensor hardware',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _toggleSession,
              icon: const Icon(Icons.play_arrow),
              label: const Text('START LIVE SESSION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<BlynkStatus>(
      stream: _service.statusStream,
      initialData: _service.currentStatus,
      builder: (context, statusSnapshot) {
        final status = statusSnapshot.data ?? BlynkStatus.offline;

        return StreamBuilder<BiosensorData?>(
          stream: _service.dataStream,
          builder: (context, snapshot) {
            final data = snapshot.data;
            // If loading, show loader
            if (status == BlynkStatus.loading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Connecting to device...',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Treat loading as connected to avoid flashing red "Offline" banner during transitions
            final isConnected = status != BlynkStatus.offline;

            final hr = data?.heartRate.toString() ?? '--';
            final spo2 = data?.spo2.toString() ?? '--';
            final gsr = data?.gsr.toStringAsFixed(1) ?? '--';
            final isStressed = data?.isStressed ?? false;

            return Padding(
              padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
              child: Column(
                children: [
                  _buildHeader(context, isConnected),
                  const SizedBox(height: 16),
                  if (!isConnected)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sensors_off,
                            color: Colors.red[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hardware Offline',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                                Text(
                                  'ESP32 disconnected. Check debug logs below.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.red[600],
                                  ),
                                ),
                                if (_service.lastError.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Debug: ${_service.lastError}',
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 10,
                                        color: Colors.red[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _service.stopSimulation();
                              Future.delayed(
                                const Duration(milliseconds: 500),
                                () {
                                  _service.startSimulation();
                                },
                              );
                            },
                            child: Text(
                              'RETRY',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: isDesktop
                        ? _buildDesktopContent(
                            context,
                            isConnected,
                            hr,
                            spo2,
                            gsr,
                            isStressed,
                          )
                        : _buildTabletMobileContent(
                            context,
                            isConnected,
                            hr,
                            spo2,
                            gsr,
                            isStressed,
                            isTablet,
                          ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    bool hasData,
    String hr,
    String spo2,
    String gsr,
    bool isStressed,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2, // Reduced from 3 to give more space to right panel
          child: Column(
            children: [
              // 3 Sensor Cards: Heart Beat, SpO2, GSR
              Row(
                children: [
                  Expanded(
                    child: TelemetryCard(
                      title: 'Heart Rate',
                      value: hr,
                      unit: 'BPM',
                      icon: Icons.favorite,
                      color: isStressed ? Colors.orange : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TelemetryCard(
                      title: 'SpO2',
                      value: spo2,
                      unit: '%',
                      icon: Icons.water_drop,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TelemetryCard(
                      title: 'GSR',
                      value: gsr,
                      unit: 'µS',
                      icon: Icons.bolt,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Charts
              Expanded(child: _buildChartCard(context)),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Sidebar (Stress Score & AI) - Increased width
        Expanded(
          flex: 1, // Stays 1, but relative to flex:2 gives ~33% width
          child: Column(
            children: [
              _stressScoreCard(context),
              const SizedBox(height: 24),
              // Use Expanded here for desktop sidebar to fill space
              Expanded(child: _aiInsightsCard(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletMobileContent(
    BuildContext context,
    bool hasData,
    String hr,
    String spo2,
    String gsr,
    bool isStressed,
    bool isTablet,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3 Sensor Cards: Heart Beat, SpO2, GSR
          if (isTablet)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TelemetryCard(
                        title: 'Heart Rate',
                        value: hr,
                        unit: 'BPM',
                        icon: Icons.favorite,
                        color: isStressed ? Colors.orange : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TelemetryCard(
                        title: 'SpO2',
                        value: spo2,
                        unit: '%',
                        icon: Icons.water_drop,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TelemetryCard(
                  title: 'GSR',
                  value: gsr,
                  unit: 'µS',
                  icon: Icons.bolt,
                  color: Colors.purple,
                ),
              ],
            )
          else
            Column(
              children: [
                TelemetryCard(
                  title: 'Heart Rate',
                  value: hr,
                  unit: 'BPM',
                  icon: Icons.favorite,
                  color: isStressed ? Colors.orange : Colors.red,
                ),
                const SizedBox(height: 12),
                TelemetryCard(
                  title: 'SpO2',
                  value: spo2,
                  unit: '%',
                  icon: Icons.water_drop,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                TelemetryCard(
                  title: 'GSR',
                  value: gsr,
                  unit: 'µS',
                  icon: Icons.bolt,
                  color: Colors.purple,
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Chart
          SizedBox(height: 300, child: _buildChartCard(context)),

          const SizedBox(height: 24),

          // Stress Score Card
          _stressScoreCard(context),

          const SizedBox(height: 24),

          // AI Insights Card
          _aiInsightsCard(context),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.show_chart,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Physiological Trends',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Legend
                Row(children: [_legendItem('ECG', Colors.redAccent)]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: TelemetryChart(dataStream: _service.dataStream)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isOnline) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monitor_heart,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Patient Monitoring',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Text(
                        'LIVE SESSION',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Real-time biofeedback stream & AI analysis',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isOnline ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOnline ? Colors.green[100]! : Colors.red[100]!,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? 'STREAM ONLINE' : 'STREAM OFFLINE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'SESSION TIMER',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  _formatDuration(_sessionDuration),
                  style: GoogleFonts.robotoMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Replaced multiple stop buttons with a single "End Session"
            TextButton.icon(
              onPressed: _toggleSession,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              label: const Text(
                'END SESSION',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _stressScoreCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMPOSITE STRESS SCORE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              StreamBuilder<BiosensorData?>(
                stream: _service.dataStream,
                builder: (context, snapshot) {
                  // Stress calculation based on Heart Rate and SpO2
                  // Higher HR (>100) and lower SpO2 (<95) = Higher Stress
                  double score = 0.0;
                  if (snapshot.hasData && snapshot.data != null) {
                    final data = snapshot.data!;

                    // ZERO CHECK: If sensors are 0, stress is 0
                    if (data.heartRate == 0 && data.spo2 == 0) {
                      score = 0.0;
                    } else {
                      // Normalize HR: 60=0, 140=10 (Ensure non-negative)
                      double hrScore = ((data.heartRate - 60) / 80) * 10;
                      if (hrScore < 0) hrScore = 0;

                      // Normalize SpO2: 100=0, 90=10 (inverted)
                      double spo2Score = ((100 - data.spo2) / 10) * 10;
                      if (spo2Score < 0) spo2Score = 0;

                      // Combined score
                      score = (hrScore + spo2Score) / 2;
                      score = score.clamp(0.0, 10.0);
                    }
                  } else {
                    return Text(
                      '--',
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey[400],
                      ),
                    );
                  }
                  return Text(
                    score.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: score > 5 ? Colors.orange : Colors.green,
                    ),
                  );
                },
              ),
              Text(
                '/ 10',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.35, // Dynamicize later
              minHeight: 8,
              backgroundColor: Colors.grey[100],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Patient state is optimal.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiInsightsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.purple[400]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Clinical Insights',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              // Recording Toggle Button
              GestureDetector(
                onTap: _isSessionActive ? _toggleRecording : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _transcriptionService.isListening
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _transcriptionService.isListening
                          ? Colors.red.withValues(alpha: 0.3)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _transcriptionService.isListening
                            ? Icons.mic
                            : Icons.mic_off,
                        color: _transcriptionService.isListening
                            ? Colors.red
                            : Colors.grey[600],
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _transcriptionService.isListening ? 'REC' : 'MIC',
                        style: GoogleFonts.inter(
                          color: _transcriptionService.isListening
                              ? Colors.red
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Insight Display Area - Flexible height
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: _isGeneratingInsight
                  ? Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Analyzing...',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _aiInsight ??
                            'Click "Generate Insight" to analyze current session data.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.5,
                          color: _aiInsight != null
                              ? Colors.black87
                              : Colors.grey[500],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingInsight ? null : _generateInsight,
              icon: const Icon(Icons.psychology, size: 18),
              label: Text(
                'Generate Insight',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrand,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateInsight() async {
    setState(() => _isGeneratingInsight = true);

    final sensorData = await _service.dataStream.first;

    if (!mounted) return;

    if (sensorData == null) {
      setState(() {
        _aiInsight = 'Cannot generate insights while hardware is offline.';
        _isGeneratingInsight = false;
      });
      return;
    }

    final geminiService = Provider.of<GeminiService>(context, listen: false);

    // Combine notes with transcription
    String contextText = _notesController.text;
    if (_transcription.isNotEmpty) {
      contextText += '\n\n[Live Session Transcript]:\n$_transcription';
    }

    try {
      final insight = await geminiService.analyzeSession({
        'heartRate': sensorData.heartRate,
        'spo2': sensorData.spo2,
        'gsr': sensorData.gsr,
        'isStressed': sensorData.isStressed,
      }, contextText);

      if (mounted) {
        setState(() {
          _aiInsight = insight;
          _isGeneratingInsight = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiInsight = 'Error generating insight: $e';
          _isGeneratingInsight = false;
        });
      }
    }
  }

  /// Auto-generates insights periodically during the session
  void _autoGenerateInsight() async {
    if (!mounted || !_isSessionActive || _sessionTimelineData.isEmpty) return;

    setState(() => _isGeneratingInsight = true);

    // Get recent data (last 15 entries = 15 seconds of data)
    final recentData = _sessionTimelineData.length > 15
        ? _sessionTimelineData.sublist(_sessionTimelineData.length - 15)
        : _sessionTimelineData;

    // Calculate averages for the recent window
    int avgHr = 0;
    int avgSpo2 = 0;
    int stressCount = 0;

    if (recentData.isNotEmpty) {
      avgHr =
          (recentData
                      .map((e) => e['heartRate'] as int)
                      .reduce((a, b) => a + b) /
                  recentData.length)
              .round();
      avgSpo2 =
          (recentData.map((e) => e['spo2'] as int).reduce((a, b) => a + b) /
                  recentData.length)
              .round();
      stressCount = recentData.where((e) => e['isStressed'] == true).length;
    }

    final geminiService = Provider.of<GeminiService>(context, listen: false);

    try {
      final insight = await geminiService.analyzeLiveSession(
        avgHr,
        avgSpo2,
        stressCount,
        _transcription,
        _formatDuration(_sessionDuration),
      );

      if (mounted) {
        setState(() {
          _aiInsight = insight;
          _isGeneratingInsight = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiInsight = 'Live analysis unavailable: $e';
          _isGeneratingInsight = false;
        });
      }
    }
  }
}

class _SessionSummaryDialog extends StatefulWidget {
  final String transcript;
  final String duration;
  final Map<String, dynamic> avgStats;
  final List<Map<String, dynamic>> timelineData;
  final String patientId;
  final String patientName;

  const _SessionSummaryDialog({
    required this.transcript,
    required this.duration,
    required this.avgStats,
    required this.timelineData,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<_SessionSummaryDialog> createState() => _SessionSummaryDialogState();
}

class _SessionSummaryDialogState extends State<_SessionSummaryDialog> {
  bool _isLoading = false;
  String? _report;

  void _generateReport() async {
    setState(() => _isLoading = true);
    final service = Provider.of<GeminiService>(context, listen: false);
    final report = await service.generateSessionReport(
      widget.transcript,
      widget.duration,
      widget.avgStats,
      widget.timelineData,
    );
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
      // Show report in bigger popup
      if (report != null && report.isNotEmpty) {
        _showReportPopup(report);
      }
    }
  }

  void _showReportPopup(String report) {
    showDialog(
      context: context,
      builder: (context) => _ReportViewDialog(
        report: report,
        duration: widget.duration,
        avgStats: widget.avgStats,
        transcript: widget.transcript,
        timelineData: widget.timelineData,
        patientId: widget.patientId,
        patientName: widget.patientName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Session Complete',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Session Duration: ${widget.duration}',
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
<<<<<<< HEAD
                 _statItem('Avg Heart Rate', '${widget.avgStats['avgHr']} BPM', Icons.favorite, Colors.red),
                 _statItem('Avg SpO2', '${widget.avgStats['avgSpo2']}%', Icons.water_drop, Colors.blue),
                 _statItem('Avg GSR', '${widget.avgStats['avgGsr']} µS', Icons.electric_bolt, Colors.orange),
=======
                _statItem(
                  'Avg Heart Rate',
                  '${widget.avgStats['avgHr']} BPM',
                  Icons.favorite,
                  Colors.red,
                ),
                _statItem(
                  'Avg SpO2',
                  '${widget.avgStats['avgSpo2']}%',
                  Icons.water_drop,
                  Colors.blue,
                ),
>>>>>>> 4c923598cbcf60d7f4e3c82d1179b9a418f99261
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Transcript',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.transcript.isEmpty
                        ? 'No speech detected.'
                        : widget.transcript,
                    style: GoogleFonts.inter(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
<<<<<<< HEAD
                icon: _isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.description),
                label: Text(_isLoading ? 'Generating Report...' : 'Generate Detailed Medical Report'),
=======
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.description),
                label: Text(
                  _isLoading
                      ? 'Generating Report...'
                      : 'Generate Detailed Medical Report',
                ),
>>>>>>> 4c923598cbcf60d7f4e3c82d1179b9a418f99261
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
<<<<<<< HEAD
=======
            if (_report != null)
              Expanded(
                flex: 3, // Give more space to report
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _report!,
                      style: GoogleFonts.inter(fontSize: 14, height: 1.6),
                    ),
                  ),
                ),
              ),
>>>>>>> 4c923598cbcf60d7f4e3c82d1179b9a418f99261
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

/// Large popup dialog to display the generated report
class _ReportViewDialog extends StatefulWidget {
  final String report;
  final String duration;
  final Map<String, dynamic> avgStats;
  final String transcript;
  final List<Map<String, dynamic>> timelineData;
  final String patientId;
  final String patientName;

  const _ReportViewDialog({
    required this.report,
    required this.duration,
    required this.avgStats,
    required this.transcript,
    required this.timelineData,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<_ReportViewDialog> createState() => _ReportViewDialogState();
}

class _ReportViewDialogState extends State<_ReportViewDialog> {
  bool _isSaving = false;

  void _saveToHistory() async {
    setState(() => _isSaving = true);
    
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // Calculate peak heart rate from timeline data
      int peakHr = 0;
      for (var data in widget.timelineData) {
        final hr = data['heartRate'] as int? ?? 0;
        if (hr > peakHr) peakHr = hr;
      }
      
      // Parse duration string to get minutes (format: "MM:SS")
      final parts = widget.duration.split(':');
      final durationMinutes = int.tryParse(parts[0]) ?? 0;
      
      // Save session to Firestore
      await firestoreService.addSession(
        widget.patientId, // Use selected patient ID
        {
          'patientName': widget.patientName, // Store patient name
          'startTime': Timestamp.now(),
          'durationMinutes': durationMinutes,
          'status': 'Completed',
          'peakHeartRate': peakHr,
          'avgHeartRate': widget.avgStats['avgHr'],
          'avgSpo2': widget.avgStats['avgSpo2'],
          'transcript': widget.transcript,
          'aiReport': widget.report,
          'timelineData': widget.timelineData,
        },
      );
      
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session saved to history!'),
            backgroundColor: Colors.green,
          ),
        );
        // Close both dialogs and return to live session
        Navigator.of(context).pop(); // Close report dialog
        Navigator.of(context).pop(); // Close session summary dialog
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: screenSize.width * 0.8,
        height: screenSize.height * 0.85,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Medical Report', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Session Duration: ${widget.duration}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniStat('Avg HR', '${widget.avgStats['avgHr']} BPM', Icons.favorite, Colors.red),
                  _miniStat('Avg SpO2', '${widget.avgStats['avgSpo2']}%', Icons.water_drop, Colors.blue),
                  _miniStat('Avg GSR', '${widget.avgStats['avgGsr']} µS', Icons.electric_bolt, Colors.orange),
                  _miniStat('Data Points', '${widget.timelineData.length}', Icons.timeline, Colors.purple),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Report Content - Takes most of the space
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[50]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.report,
                    style: GoogleFonts.inter(fontSize: 15, height: 1.7, color: Colors.black87),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveToHistory,
                    icon: _isSaving 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save to History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
