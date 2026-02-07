import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      color: const Color(0xFFF8FAFC), // very light grey
      child: Column(
        children: [
          isDesktop 
          ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _brandColumn()),
              Expanded(flex: 2, child: _linkColumn('Product', ['Core Dashboard', 'Sensor Hardware', 'AI Analysis Engine', 'API Access'])),
              Expanded(flex: 2, child: _linkColumn('Resources', ['Documentation', 'Clinical Studies', 'Help Center', 'Status'])),
              Expanded(flex: 3, child: _subscribeColumn()),
            ],
          )
          : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _brandColumn(),
              const SizedBox(height: 32),
              _linkColumn('Product', ['Core Dashboard', 'Sensor Hardware', 'AI Analysis Engine', 'API Access']),
              const SizedBox(height: 32),
              _linkColumn('Resources', ['Documentation', 'Clinical Studies', 'Help Center', 'Status']),
              const SizedBox(height: 32),
              _subscribeColumn(),
            ],
          ),
          const SizedBox(height: 64),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2024 Neurowell Inc. All rights reserved.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400]),
              ),
              if (isDesktop)
                Row(
                  children: [
                    Text('Privacy Policy', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
                    const SizedBox(width: 24),
                    Text('Terms of Service', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
                    const SizedBox(width: 24),
                    Text('HIPAA Compliance', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _brandColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primaryBrand,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.appName,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Advancing clinical therapy through precision physiological data and AI-driven insights.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _linkColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            link,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        )),
      ],
    );
  }

  Widget _subscribeColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stay Updated',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
             children: [
               Expanded(
                 child: TextField(
                   decoration: InputDecoration(
                     hintText: 'clinician@hospital.com',
                     hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500]),
                     border: InputBorder.none,
                     isDense: true,
                     contentPadding: const EdgeInsets.symmetric(vertical: 14),
                   ),
                 ),
               ),
               Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBrand,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward, color: Colors.white, size: 16),
               ),
             ],
           ),
         ),
         const SizedBox(height: 24),
         Row(
           children: [
             Icon(Icons.language, color: Colors.grey[600], size: 20),
             const SizedBox(width: 16),
             Icon(Icons.alternate_email, color: Colors.grey[600], size: 20),
             const SizedBox(width: 16),
             Icon(Icons.share, color: Colors.grey[600], size: 20),
           ],
        ),
      ],
    );
  }
}
