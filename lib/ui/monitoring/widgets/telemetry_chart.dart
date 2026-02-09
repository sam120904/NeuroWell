import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'dart:async';
import '../../../data/models/biosensor_data_model.dart';

class TelemetryChart extends StatefulWidget {
  final Stream<BiosensorData?> dataStream;

  const TelemetryChart({super.key, required this.dataStream});

  @override
  State<TelemetryChart> createState() => _TelemetryChartState();
}

class _TelemetryChartState extends State<TelemetryChart> {
  final List<FlSpot> _scanLine = [];
  StreamSubscription? _subscription;
  double _xValue = 0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.dataStream.listen((data) {
      if (data != null && data.ecgData.isNotEmpty) {
        _updateData(data.ecgData);
      }
    });
  }

  void _updateData(List<double> newPoints) {
    if (!mounted) return;

    // Add new points
    for (var point in newPoints) {
      _scanLine.add(FlSpot(_xValue, point));
      _xValue += 0.01; // Scale time
    }

    // Keep last 300 points (approx 3 seconds window)
    if (_scanLine.length > 300) {
      _scanLine.removeRange(0, _scanLine.length - 300);
    }

    setState(() {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: const FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ), // Hide time for waveform
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        // Dynamic X window based on data
        minX: _scanLine.isNotEmpty ? _scanLine.first.x : 0,
        maxX: _scanLine.isNotEmpty ? _scanLine.last.x : 10,
        minY: -2,
        maxY: 2,
        lineBarsData: [
          // ECG Waveform
          LineChartBarData(
            spots: _scanLine.isEmpty ? [const FlSpot(0, 0)] : _scanLine,
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.redAccent.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }
}
