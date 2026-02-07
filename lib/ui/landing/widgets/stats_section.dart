import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      color: Colors.white, // Keep it clean
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem('99.9%', 'UPTIME RELIABILITY'),
                _statItem('15ms', 'LATENCY AVERAGE'),
                _statItem('10k+', 'ACTIVE PATIENTS'),
                _statItem('24/7', 'CLINICAL SUPPORT'),
              ],
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem('99.9%', 'UPTIME RELIABILITY'),
                    _statItem('15ms', 'LATENCY AVERAGE'),
                  ],
                ),
                const SizedBox(height: 32),
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem('10k+', 'ACTIVE PATIENTS'),
                     _statItem('24/7', 'CLINICAL SUPPORT'),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryBrand,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.grey,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
