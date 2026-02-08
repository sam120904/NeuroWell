import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import 'widgets/telemetry_card.dart';
import 'widgets/telemetry_chart.dart';
import '../../data/services/biosensor_service.dart';
import '../../data/services/blynk_service.dart';
import 'package:provider/provider.dart';
import '../../data/services/gemini_service.dart';
import '../../data/models/biosensor_data_model.dart';
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
  
  // Timer State
  Timer? _sessionTimer;
  StreamSubscription? _dataSubscription;
  Duration _sessionDuration = Duration.zero;
  final List<Map<String, dynamic>> _sessionTimelineData = []; // Store session data points
  
  @override
  void initState() {
    super.initState();
    print('[LiveView] initState');
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
    print('[LiveView] dispose');
    _service.stopSimulation();
    _transcriptionService.dispose();
    _sessionTimer?.cancel();
    _dataSubscription?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleSession() async {
    if (_isSessionActive) {
      // Logic when turning OFF
      _sessionTimer?.cancel();
      _dataSubscription?.cancel();
      _service.stopSimulation();
      await _transcriptionService.stopListening();
      
      if (mounted) {
        setState(() => _isSessionActive = false);
        _showSessionSummary();
      }
    } else {
      // Logic when turning ON
      setState(() {
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
            'isStressed': data.isStressed,
          });
        }
      });
      
      _service.startSimulation();
      await _transcriptionService.startListening();
    }
  }

  void _showSessionSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SessionSummaryDialog(
        transcript: _transcription,
        duration: _formatDuration(_sessionDuration),
        timelineData: List.from(_sessionTimelineData), // Pass copy of data
        // Placeholder stats - in real app, calculate these from session data
        avgStats: {
          'avgHr': _sessionTimelineData.isEmpty ? 0 : (_sessionTimelineData.map((e) => e['heartRate'] as int).reduce((a, b) => a + b) / _sessionTimelineData.length).toStringAsFixed(0),
          'avgSpo2': _sessionTimelineData.isEmpty ? 0 : (_sessionTimelineData.map((e) => e['spo2'] as int).reduce((a, b) => a + b) / _sessionTimelineData.length).toStringAsFixed(0),
          'stressEvents': _sessionTimelineData.where((e) => e['isStressed'] == true).length,
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
            Icon(Icons.monitor_heart_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Live Monitoring Stopped',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sensors_off, color: Colors.red[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hardware Offline',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red[700]),
                                ),
                                Text(
                                  'ESP32 disconnected. Check debug logs below.',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.red[600]),
                                ),
                                if (_service.lastError.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Debug: ${_service.lastError}',
                                      style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.red[800], fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _service.stopSimulation();
                              Future.delayed(const Duration(milliseconds: 500), () {
                                _service.startSimulation();
                              });
                            },
                            child: Text('RETRY', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red[800])),
                          )
                        ],
                      ),
                    ),
                  
                  Expanded(
                    child: isDesktop 
                        ? _buildDesktopContent(context, isConnected, hr, spo2, gsr, isStressed)
                        : _buildTabletMobileContent(context, isConnected, hr, spo2, gsr, isStressed, isTablet),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildDesktopContent(BuildContext context, bool hasData, String hr, String spo2, String gsr, bool isStressed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // 3 Sensor Cards: Heart Beat, SpO2, GSR
              Row(
                children: [
                  Expanded(child: TelemetryCard(title: 'Heart Rate', value: hr, unit: 'BPM', icon: Icons.favorite, color: isStressed ? Colors.orange : Colors.red)),
                  const SizedBox(width: 16),
                  Expanded(child: TelemetryCard(title: 'SpO2', value: spo2, unit: '%', icon: Icons.water_drop, color: Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: TelemetryCard(title: 'GSR', value: gsr, unit: 'µS', icon: Icons.bolt, color: Colors.purple)),
                ],
              ),
              const SizedBox(height: 24),
              // Charts
              Expanded(child: _buildChartCard(context)),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Sidebar (Stress Score & AI)
        Expanded(
          flex: 1,
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

  Widget _buildTabletMobileContent(BuildContext context, bool hasData, String hr, String spo2, String gsr, bool isStressed, bool isTablet) {
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
                    Expanded(child: TelemetryCard(title: 'Heart Rate', value: hr, unit: 'BPM', icon: Icons.favorite, color: isStressed ? Colors.orange : Colors.red)),
                    const SizedBox(width: 12),
                    Expanded(child: TelemetryCard(title: 'SpO2', value: spo2, unit: '%', icon: Icons.water_drop, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 12),
                TelemetryCard(title: 'GSR', value: gsr, unit: 'µS', icon: Icons.bolt, color: Colors.purple),
              ],
            )
          else
            Column(
              children: [
                TelemetryCard(title: 'Heart Rate', value: hr, unit: 'BPM', icon: Icons.favorite, color: isStressed ? Colors.orange : Colors.red),
                const SizedBox(height: 12),
                TelemetryCard(title: 'SpO2', value: spo2, unit: '%', icon: Icons.water_drop, color: Colors.blue),
                const SizedBox(height: 12),
                TelemetryCard(title: 'GSR', value: gsr, unit: 'µS', icon: Icons.bolt, color: Colors.purple),
              ],
            ),

          const SizedBox(height: 24),

          // Chart
          SizedBox(
            height: 300,
            child: _buildChartCard(context),
          ),

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
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                      child: const Icon(Icons.show_chart, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Physiological Trends',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 24),
                  // Legend
                  Row(
                    children: [
                      _legendItem('ECG', Colors.redAccent),
                    ],
                  ),
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
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.monitor_heart, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Patient Monitoring',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Text('Real-time biofeedback stream & AI analysis',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
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
                border: Border.all(color: isOnline ? Colors.green[100]! : Colors.red[100]!),
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
                Text('SESSION TIMER',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(
                    _formatDuration(_sessionDuration),
                    style: GoogleFonts.robotoMono(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
            const SizedBox(width: 24),
            // Replaced multiple stop buttons with a single "End Session"
            TextButton.icon(
              onPressed: _toggleSession,
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              label: const Text('END SESSION', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _stressScoreCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMPOSITE STRESS SCORE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
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
                    return Text('--', style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.grey[400]));
                  }
                  return Text(score.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w900, color: score > 5 ? Colors.orange : Colors.green));
                }
              ),
              Text('/ 10', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.35, // Dynamicize later
              minHeight: 8,
              backgroundColor: Colors.grey[100],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Text('Patient state is optimal.', style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _aiInsightsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Allow it to shrink
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Clinical Insights', 
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)
                  ),
                ),
                if (_transcriptionService.isListening)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                         const Icon(Icons.mic, color: Colors.red, size: 14),
                         const SizedBox(width: 4),
                         Text('REC', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Transcription View
          Container(
             height: 80,
             width: double.infinity,
             padding: const EdgeInsets.all(8),
             margin: const EdgeInsets.only(bottom: 12),
             decoration: BoxDecoration(
               color: Colors.grey[50], 
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: Colors.grey[200]!)
             ),
             child: SingleChildScrollView(
               child: Text(
                 _transcription.isEmpty ? 'Waiting for speech...' : _transcription,
                 style: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12),
               ),
             ),
          ),
          TextField(
            controller: _notesController,
            maxLines: 2, 
            decoration: InputDecoration(
              hintText: 'Enter clinical observations...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingInsight ? null : _generateInsight,
              icon: _isGeneratingInsight 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.psychology),
              label: Text(_isGeneratingInsight ? 'Analyzing...' : 'Generate Insight'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Flexible container for insights
          Container(
            height: 200, // Fixed height for insights to prevent overflow
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            child: SingleChildScrollView(
              child: _aiInsight != null
                  ? Text(
                      _aiInsight!,
                      style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.black87),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 32, color: AppColors.primary.withOpacity(0.3)),
                        const SizedBox(height: 8),
                        Text(
                          'Enter notes and click generate to get AI-powered insights based on live sensor data.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        ),
                      ],
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
}

class _SessionSummaryDialog extends StatefulWidget {
  final String transcript;
  final String duration;
  final Map<String, dynamic> avgStats;
  final List<Map<String, dynamic>> timelineData;

  const _SessionSummaryDialog({
    required this.transcript,
    required this.duration,
    required this.avgStats,
    required this.timelineData,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Container(
        width: 600,
        height: 600, // Fixed height for dialog
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Session Complete', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Session Duration: ${widget.duration}', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                 _statItem('Avg Heart Rate', '${widget.avgStats['avgHr']} BPM', Icons.favorite, Colors.red),
                 _statItem('Avg SpO2', '${widget.avgStats['avgSpo2']}%', Icons.water_drop, Colors.blue),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text('Transcript', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50], 
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!)
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.transcript.isEmpty ? 'No speech detected.' : widget.transcript,
                  style: GoogleFonts.inter(color: Colors.grey[700]),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                icon: _isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.description),
                label: Text(_isLoading ? 'Generating Report...' : 'Generate Detailed Medical Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_report != null)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(_report!, style: GoogleFonts.inter(fontSize: 12)),
                  ),
                ),
              )
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
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
