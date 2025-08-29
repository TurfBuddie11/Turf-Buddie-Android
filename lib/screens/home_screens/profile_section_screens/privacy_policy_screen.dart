import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo.shade700, Colors.indigo.shade400],
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(context),
            const SizedBox(height: 20),
            _buildPolicySection(
              context,
              title: 'Information Collection & Use',
              icon: Icons.collections_bookmark,
              color: Colors.blueAccent,
              points: const [
                'The Turf Buddie app ("Application") collects:',
                '• IP address, visited pages, usage time, and OS details',
                '• Location data for personalized services and analytics',
                '• Anonymized data may be shared with third-party services',
              ],
            ),
            _buildPolicySection(
              context,
              title: 'Third-Party Services',
              icon: Icons.extension,
              color: Colors.purpleAccent,
              points: const [
                'The Application uses third-party services like:',
                '• Firebase Crashlytics',
                '• Google Maps',
              ],
            ),
            _buildPolicySection(
              context,
              title: 'Opt-Out & Data Retention',
              icon: Icons.settings,
              color: Colors.teal,
              points: const [
                '• Uninstalling the Application stops data collection',
                '• Data is retained while using the app',
                '• Request deletion via turfbuddie11@gmail.com',
              ],
            ),
            _buildPolicySection(
              context,
              title: 'Children',
              icon: Icons.child_care,
              color: Colors.orange,
              points: const [
                '• No data is knowingly collected from children under 13',
                '• Contact us for removal if necessary',
              ],
            ),
            _buildPolicySection(
              context,
              title: 'Security',
              icon: Icons.security,
              color: Colors.green,
              points: const [
                'We implement safeguards to protect user data',
              ],
            ),
            _buildPolicySection(
              context,
              title: 'Changes',
              icon: Icons.update,
              color: Colors.amber,
              points: const [
                'Policy updates may occur',
                'Continued use implies acceptance',
              ],
            ),
            const SizedBox(height: 20),
            _buildContactSection(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.indigo.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.privacy_tip,
              size: 40,
              color: Colors.indigo.shade700,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Turf Buddie Privacy Policy',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.indigo.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Divider(
          color: Colors.grey.shade300,
          thickness: 1,
        ),
      ],
    );
  }

  Widget _buildPolicySection(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required List<String> points,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: points.map((point) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (point.startsWith('•'))
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 8),
                          child: Icon(
                            Icons.circle,
                            size: 6,
                            color: color,
                          ),
                        )
                      else
                        const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          point.replaceAll('•', '').trim(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.indigo.shade100,
          width: 1,
        ),
      ),
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Contact Us',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.indigo.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'For any privacy concerns or questions about our policy',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email,
                  color: Colors.redAccent,
                ),
              ),
              title: Text(
                'Email us at',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              subtitle: Text(
                'turfbuddie11@gmail.com',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.indigo.shade800,
                ),
              ),
              onTap: () => _launchEmail('turfbuddie11@gmail.com'),
            ),
            const SizedBox(height: 10),
            Text(
              'We take your privacy seriously and will respond promptly',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}