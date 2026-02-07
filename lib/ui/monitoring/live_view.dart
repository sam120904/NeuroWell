import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import 'widgets/telemetry_card.dart';
import 'widgets/telemetry_chart.dart';
import '../../data/services/biosensor_service.dart';
import '../../data/models/biosensor_data_model.dart';

class LiveMonitoringView extends StatefulWidget {
  const LiveMonitoringView({super.key});

  @override
  State<LiveMonitoringView> createState() => _LiveMonitoringViewState();
}

class _LiveMonitoringViewState extends State<LiveMonitoringView> {
  final BiosensorService _service = BiosensorService();

  @override
  void initState() {
    super.initState();
    _service.startSimulation();
  }

  @override
  void dispose() {
    _service.stopSimulation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BiosensorData>(
      stream: _service.dataStream,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final hr = data?.heartRate.toString() ?? '--';
        final spo2 = data?.oxygenSaturation.toString() ?? '--';
        final hrv = data?.hrv.toString() ?? '--';
        final gsr = data?.gsr.toString() ?? '--';

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              _buildHeader(context, snapshot.hasData),
              const SizedBox(height: 32),

              // Grid
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          // Cards
                          Row(
                            children: [
                              Expanded(child: TelemetryCard(title: 'Heart Rate', value: hr, unit: 'BPM', icon: Icons.favorite, color: Colors.red)),
                              const SizedBox(width: 16),
                              Expanded(child: TelemetryCard(title: 'Blood Oxygen', value: spo2, unit: '%', icon: Icons.water_drop, color: Colors.blue)),
                              const SizedBox(width: 16),
                              Expanded(child: TelemetryCard(title: 'HRV', value: hrv, unit: 'ms', icon: Icons.timer, color: Colors.amber)),
                              const SizedBox(width: 16),
                              Expanded(child: TelemetryCard(title: 'GSR', value: gsr, unit: 'µS', icon: Icons.bolt, color: Colors.purple)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Charts
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
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
                                      // Legend
                                      Row(
                                        children: [
                                          _legendItem('Heart Rate', Colors.redAccent),
                                          const SizedBox(width: 16),
                                          _legendItem('HRV', Colors.amber),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const Expanded(child: TelemetryChart()), // Note: Chart needs to accept data points to animate
                                ],
                              ),
                            ),
                          ),
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
                ),
              ),
            ],
          ),
        );
      }
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
               StreamBuilder<BiosensorData>(
                stream: _service.dataStream,
                builder: (context, snapshot) {
                  // Mock calculation: Normalize HRV and GSR to a score 0-10
                  // Low HRV + High GSR = High Stress
                  double score = 3.5;
                  if (snapshot.hasData) {
                     // Simple mock logic
                     score = (100 - snapshot.data!.hrv) / 10;
                     if(score < 0) score = 0;
                     if(score > 10) score = 10;
                  }
                  return Text(score.toStringAsFixed(1), style: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w900));
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text('AI Insights', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                    child: Icon(Icons.psychology, size: 32, color: AppColors.primary.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 16),
                  Text('Waiting for analysis...', style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[400])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
