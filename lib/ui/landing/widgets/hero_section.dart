import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      color: const Color(0xFFF1F5F9), // Very light grey background for Hero
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: _buildLeftContent(context)),
                const SizedBox(width: 48),
                Expanded(flex: 6, child: _buildRightContent(context)),
              ],
            )
          : Column(
              children: [
                _buildLeftContent(context),
                const SizedBox(height: 48),
                _buildRightContent(context),
              ],
            ),
    );
  }

  Widget _buildLeftContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[50], // Very light blue
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBrand,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'NOW WITH AI INSIGHTS',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: AppColors.primaryBrand,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: AppColors.primary,
              letterSpacing: -1.0,
            ),
            children: const [
              TextSpan(text: 'Biofeedback\n'),
              TextSpan(text: 'Reimagined for\n'),
              TextSpan(text: 'Modern Therapy', style: TextStyle(color: AppColors.primaryBrand)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Experience physiological monitoring with real-time clinical metrics. Our AI-driven platform helps providers visualize neurological wellness like never before.',
          style: GoogleFonts.inter(
            fontSize: 16,
            height: 1.6,
            color: AppColors.textDim, // Darker for readability
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: AppColors.accentOrange.withValues(alpha: 0.4),
              ),
              child: Text(
                'Start Clinical Trial',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                side: BorderSide(color: Colors.grey[200]!),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Watch Demo',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),

      ],
    );
  }



  Widget _buildRightContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE PATIENT STREAM',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Clinical Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _windowControl(Colors.red),
                  _windowControl(Colors.amber),
                  _windowControl(Colors.green),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _miniStat('Heart Rate', '72', 'BPM', Colors.green, true)),
              const SizedBox(width: 16),
              Expanded(child: _miniStat('HRV (Stress)', '58', 'ms', Colors.green, true)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 20,
                      // getTitlesWidget was causing issues, using default style for now
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                       FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5), FlSpot(3, 5), FlSpot(4, 4), FlSpot(5, 6), FlSpot(6, 5.5),
                       FlSpot(7, 3), FlSpot(8, 4), FlSpot(9, 3.5), FlSpot(10, 5), FlSpot(11, 4), FlSpot(12, 6), FlSpot(13, 2),
                    ],
                    isCurved: true,
                    color: AppColors.primaryBrand,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBrand.withValues(alpha: 0.3),
                          AppColors.primaryBrand.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowControl(Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _miniStat(String label, String value, String unit, Color trendColor, bool isUp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey)),
               const SizedBox(height: 4),
               Row(
                 crossAxisAlignment: CrossAxisAlignment.baseline,
                 textBaseline: TextBaseline.alphabetic,
                 children: [
                   Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                   const SizedBox(width: 4),
                   Text(unit, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[400])),
                 ],
               ),
             ],
           ),
           Icon(
             isUp ? Icons.trending_up : Icons.trending_down,
             color: trendColor,
             size: 20,
           ),
        ],
      ),
    );
  }
}
