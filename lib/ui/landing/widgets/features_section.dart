import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 3 Cards Layout
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Clinical Excellence',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Advanced tools designed specifically for modern healthcare providers to deliver better patient outcomes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              color: AppColors.textDim, // Darker grey for readability
              height: 1.5,
            ),
          ),
          const SizedBox(height: 64),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _featureCard(
                        icon: Icons.graphic_eq,
                        color: Colors.redAccent,
                        title: 'Real-time Monitoring',
                        desc:
                            'Monitor patient vitals with millisecond precision. Capture granular physiological changes during therapy sessions.',
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: _featureCard(
                        icon: Icons.psychology,
                        color: Colors.blue,
                        title: 'AI Analysis',
                        desc:
                            'Automated insights powered by clinical-grade algorithms. Detect patterns in autonomic nervous system responses instantly.',
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: _featureCard(
                        icon: Icons.security,
                        color: Colors.amber,
                        title: 'Secure Reporting',
                        desc:
                            'HIPAA compliant data storage and instant report generation. Share progress with patients and medical boards securely.',
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _featureCard(
                      icon: Icons.graphic_eq,
                      color: Colors.redAccent,
                      title: 'Real-time Monitoring',
                      desc:
                          'Monitor patient vitals with millisecond precision.',
                    ),
                    const SizedBox(height: 32),
                    _featureCard(
                      icon: Icons.psychology,
                      color: Colors.blue,
                      title: 'AI Analysis',
                      desc:
                          'Automated insights powered by clinical-grade algorithms.',
                    ),
                    const SizedBox(height: 32),
                    _featureCard(
                      icon: Icons.security,
                      color: Colors.amber,
                      title: 'Secure Reporting',
                      desc:
                          'HIPAA compliant data storage and instant report generation.',
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), // Light background for icon
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: AppColors.textDim, // Darker grey for readability
            ),
          ),
        ],
      ),
    );
  }
}
