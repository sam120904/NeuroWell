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

class LiveMonitoringView extends StatefulWidget {
  const LiveMonitoringView({super.key});

  @override
  State<LiveMonitoringView> createState() => _LiveMonitoringViewState();
}

class _LiveMonitoringViewState extends State<LiveMonitoringView> {
  final BiosensorService _service = BiosensorService();
  final TextEditingController _notesController = TextEditingController();
  String? _aiInsight;
  bool _isGeneratingInsight = false;
  bool _isSessionActive = false;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _service.stopSimulation();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleSession() {
    setState(() {
      _isSessionActive = !_isSessionActive;
      if (_isSessionActive) {
        _service.startSimulation();
      } else {
        _service.stopSimulation();
      }
    });
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
                              ],
                            ),
                          ),
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
          SizedBox(
            height: 350,
            child: _aiInsightsCard(context),
          ),
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
                Text('00:00',
                    style: GoogleFonts.robotoMono(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
            const SizedBox(width: 24),
            TextButton.icon(
              onPressed: _toggleSession,
              icon: const Icon(Icons.stop, color: Colors.red),
              label: const Text('STOP SESSION', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text('END SESSION'),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text('AI Clinical Insights', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter clinical observations (e.g., "Patient appears anxious during discussion of work")...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Expanded(
            child: Container(
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
          ),
        ],
      ),
    );
  }

  void _generateInsight() async {
    setState(() => _isGeneratingInsight = true);
    
    // In a real app, you'd get the latest value from the stream or service
    // For now, we'll grab a snapshot from the service's current state if possible, 
    // or just listen once.
    final sensorData = await _service.dataStream.first; 
    
    if (!mounted) return;

    // Can't generate insight when offline (no data)
    if (sensorData == null) {
      setState(() {
        _aiInsight = 'Cannot generate insights while hardware is offline.';
        _isGeneratingInsight = false;
      });
      return;
    }

    final geminiService = Provider.of<GeminiService>(context, listen: false);
    final insight = await geminiService.analyzeSession({
      'heartRate': sensorData.heartRate,
      'spo2': sensorData.spo2,
      'gsr': sensorData.gsr,
      'isStressed': sensorData.isStressed,
    }, _notesController.text);

    if (mounted) {
      setState(() {
        _aiInsight = insight;
        _isGeneratingInsight = false;
      });
    }
  }
}
