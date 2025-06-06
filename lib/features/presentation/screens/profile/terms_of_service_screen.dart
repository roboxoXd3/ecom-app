import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
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
              'Welcome to Be Smart Mall. By accessing or using our mobile application, '
                  'you agree to be bound by these Terms of Service. Please read them carefully.',
            ),

            // Definitions
            _buildSection(
              'Definitions',
              '"App" refers to the Be Smart Mall mobile application\n'
                  '"Services" refers to all services provided through the App\n'
                  '"User" refers to anyone who accesses or uses the App\n'
                  '"Content" refers to all materials and information displayed on the App',
            ),

            // User Accounts
            _buildSection(
              'User Accounts',
              '• Users must be at least 18 years old to create an account\n'
                  '• Users are responsible for maintaining account security\n'
                  '• Users must provide accurate and complete information\n'
                  '• We reserve the right to suspend or terminate accounts',
            ),

            // Privacy Policy
            _buildSection(
              'Privacy Policy',
              'Our Privacy Policy describes how we handle the information you provide to us. '
                  'By using our App, you agree to our data practices as described in our Privacy Policy.',
            ),

            // Purchases and Payments
            _buildSection(
              'Purchases and Payments',
              '• All payments are processed securely through our payment providers\n'
                  '• Prices are subject to change without notice\n'
                  '• We reserve the right to refuse service to anyone\n'
                  '• Refunds are subject to our Refund Policy',
            ),

            // Intellectual Property
            _buildSection(
              'Intellectual Property',
              'All content, designs, and intellectual property in the App are owned by Be Smart Mall. '
                  'Users may not copy, modify, or distribute our content without permission.',
            ),

            // Prohibited Activities
            _buildSection(
              'Prohibited Activities',
              '• Violating any applicable laws or regulations\n'
                  '• Attempting to interfere with the App\'s security\n'
                  '• Using the App for unauthorized commercial purposes\n'
                  '• Harassing or harming other users',
            ),

            // Limitation of Liability
            _buildSection(
              'Limitation of Liability',
              'Be Smart Mall is not liable for any indirect, incidental, or consequential damages '
                  'arising from your use of the App or any content provided through the App.',
            ),

            // Changes to Terms
            _buildSection(
              'Changes to Terms',
              'We reserve the right to modify these terms at any time. Users will be notified '
                  'of any changes through the App or via email.',
            ),

            // Contact Information
            _buildSection(
              'Contact Information',
              'If you have any questions about these Terms, please contact us at:\n'
                  'Email: legal@shopnow.com\n'
                  'Phone: +1 234 567 890',
            ),

            // Agreement Button
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('I Agree to the Terms'),
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
}
