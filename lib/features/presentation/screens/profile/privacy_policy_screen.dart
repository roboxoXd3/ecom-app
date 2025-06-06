import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated Date
            Text(
              'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              'Introduction',
              'At Be Smart Mall, we take your privacy seriously. This Privacy Policy explains how '
                  'we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),

            // Information We Collect
            _buildSection(
              'Information We Collect',
              _buildBulletPoints([
                'Personal Information (name, email, phone number)',
                'Payment Information',
                'Device Information',
                'Location Data',
                'Usage Data',
              ]),
            ),

            // How We Use Your Information
            _buildSection(
              'How We Use Your Information',
              _buildBulletPoints([
                'Process your orders and transactions',
                'Provide customer support',
                'Send promotional communications',
                'Improve our services',
                'Detect and prevent fraud',
              ]),
            ),

            // Information Sharing
            _buildSection(
              'Information Sharing',
              'We may share your information with:\n\n'
                  '${_buildBulletPoints(['Service providers and partners', 'Payment processors', 'Legal authorities when required', 'Business partners with your consent'])}',
            ),

            // Data Security
            _buildSection(
              'Data Security',
              'We implement appropriate technical and organizational measures to protect '
                  'your personal information. However, no method of transmission over the '
                  'internet is 100% secure.',
            ),

            // Your Rights
            _buildSection(
              'Your Rights',
              'You have the right to:\n\n'
                  '${_buildBulletPoints(['Access your personal data', 'Correct inaccurate data', 'Request deletion of your data', 'Object to data processing', 'Data portability'])}',
            ),

            // Cookies and Tracking
            _buildSection(
              'Cookies and Tracking',
              'We use cookies and similar tracking technologies to improve your experience. '
                  'You can control these through your device settings.',
            ),

            // Children\'s Privacy
            _buildSection(
              'Children\'s Privacy',
              'Our services are not intended for children under 13. We do not knowingly '
                  'collect information from children under 13.',
            ),

            // Third-Party Links
            _buildSection(
              'Third-Party Links',
              'Our app may contain links to third-party websites. We are not responsible '
                  'for their privacy practices.',
            ),

            // Changes to Privacy Policy
            _buildSection(
              'Changes to Privacy Policy',
              'We may update this privacy policy from time to time. We will notify you '
                  'of any changes by posting the new policy on this page.',
            ),

            // Contact Information
            _buildSection(
              'Contact Information',
              'If you have questions about this Privacy Policy, please contact us at:\n\n'
                  'Email: privacy@shopnow.com\n'
                  'Phone: +1 234 567 890\n'
                  'Address: 123 Privacy Street, NY 10001, USA',
            ),

            // Consent Button
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('I Understand and Agree'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 24),
      ],
    );
  }

  String _buildBulletPoints(List<String> points) {
    return points.map((point) => '• $point').join('\n');
  }
}
