import 'package:flutter/material.dart';
import 'package:pdf_buddy/utils/theme.dart';
import 'package:pdf_buddy/features/merge_pdf_page.dart';
import 'package:pdf_buddy/features/split_pdf_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  void _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String url,
    required Color color,
  }) {
    return IconButton(
      icon: FaIcon(icon, color: color, size: 24),
      onPressed: () => _launchUrl(url),
    );
  }

  Widget _buildOperationCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textColor,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkBackground,
                  Color(0xFF101820),
                  AppTheme.darkBackground,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 64,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'PDF BUDDY',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.textColor,
                                letterSpacing: 3,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All processes are done locally in your browser',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Operation Cards
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: [
                          SizedBox(
                            width: 280,
                            child: _buildOperationCard(
                              context,
                              title: 'MERGE PDFs',
                              icon: Icons.merge_type,
                              color: Colors.red,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const MergePDFPage()),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 280,
                            child: _buildOperationCard(
                              context,
                              title: 'SPLIT PDF',
                              icon: Icons.call_split,
                              color: Colors.green,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SplitPDFPage()),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Footer with name and social links
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'by Mantaka Mahir',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildSocialButton(
                                  icon: FontAwesomeIcons.facebook,
                                  url: 'https://www.facebook.com/mantakamahir.decode',
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                _buildSocialButton(
                                  icon: FontAwesomeIcons.linkedin,
                                  url: 'https://www.linkedin.com/in/mantakamahir/',
                                  color: Color(0xFF0A66C2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}