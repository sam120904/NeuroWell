import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';

class LandingNavbar extends StatelessWidget {
  const LandingNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryBrand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.appName,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Desktop Links (Hidden on Mobile)
          if (MediaQuery.of(context).size.width > 800)
            Row(
              children: [
                _navLink('Platform'),
                _navLink('Solutions'),
                _navLink('Science'),
                _navLink('Evidence'),
              ],
            ),

          // Auth Buttons
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text(
                  'Log in',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Get Started',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navLink(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {},
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
