import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class TelemetryChart extends StatelessWidget {
  const TelemetryChart({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  // axisSide: meta.axisSide, 
                  meta: meta,
                  child: Text(
                    '${value.toInt()}s',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 6,
        lineBarsData: [
          // Placeholder Data Line 1 (Heart Rate)
          LineChartBarData(
            spots: const [
              FlSpot(0, 3),
              FlSpot(1, 1),
              FlSpot(2, 4),
              FlSpot(3, 3),
              FlSpot(4, 5),
              FlSpot(5, 3),
              FlSpot(6, 4),
              FlSpot(7, 3),
              FlSpot(8, 2),
              FlSpot(9, 5),
              FlSpot(10, 3),
            ],
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.redAccent.withOpacity(0.1),
            ),
          ),
          // Placeholder Data Line 2 (HRV)
          LineChartBarData(
            spots: const [
              FlSpot(0, 2),
              FlSpot(1, 3),
              FlSpot(2, 2.5),
              FlSpot(3, 2.8),
              FlSpot(4, 2.2),
              FlSpot(5, 2.9),
              FlSpot(6, 2.5),
              FlSpot(7, 3.1),
              FlSpot(8, 2.7),
              FlSpot(9, 2.4),
              FlSpot(10, 2),
            ],
            isCurved: true,
            color: Colors.amber,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
