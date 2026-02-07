import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';

class LandingNavbar extends StatelessWidget {
  const LandingNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 12 : 20),
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
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Desktop Links (Hidden on Mobile)
          if (!isMobile)
            Row(
              children: [
                _navLink('Platform'),
                _navLink('Solutions'),
                _navLink('Science'),
                _navLink('Evidence'),
              ],
            ),

          // Auth Buttons or Hamburger Menu
          if (isMobile)
            Row(
              children: [
                // Compact Get Started button
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBrand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                // Hamburger Menu
                IconButton(
                  onPressed: () => _showMobileMenu(context),
                  icon: const Icon(Icons.menu, color: AppColors.primary),
                ),
              ],
            )
          else
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

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _mobileNavItem(context, 'Platform', Icons.dashboard_outlined),
            _mobileNavItem(context, 'Solutions', Icons.lightbulb_outline),
            _mobileNavItem(context, 'Science', Icons.science_outlined),
            _mobileNavItem(context, 'Evidence', Icons.bar_chart_outlined),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.login, color: AppColors.primary),
              title: Text('Log in', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileNavItem(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        // Handle navigation if needed
      },
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
