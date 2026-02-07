import 'package:flutter/material.dart';
import 'widgets/landing_navbar.dart';
import 'widgets/hero_section.dart';
import 'widgets/features_section.dart';
import 'widgets/stats_section.dart';
import 'widgets/footer_section.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          LandingNavbar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  HeroSection(),
                  StatsSection(), // Inserted new section
                  FeaturesSection(),
                  FooterSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
