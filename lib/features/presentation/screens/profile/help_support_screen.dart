import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search FAQs',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Help Section
          const Text(
            'Quick Help',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildQuickHelpCard(
                icon: Icons.local_shipping_outlined,
                title: 'Shipping Info',
                onTap: () {
                  // TODO: Navigate to shipping info
                },
              ),
              _buildQuickHelpCard(
                icon: Icons.assignment_return_outlined,
                title: 'Returns',
                onTap: () {
                  // TODO: Navigate to returns info
                },
              ),
              _buildQuickHelpCard(
                icon: Icons.payment_outlined,
                title: 'Payment',
                onTap: () {
                  // TODO: Navigate to payment info
                },
              ),
              _buildQuickHelpCard(
                icon: Icons.account_circle_outlined,
                title: 'Account',
                onTap: () {
                  // TODO: Navigate to account help
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // FAQs Section
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFaqItem(
            'How do I track my order?',
            'You can track your order in the "My Orders" section of your profile. Click on any order to view its current status and tracking information.',
          ),
          _buildFaqItem(
            'What is your return policy?',
            'We offer a 30-day return policy for most items. Items must be unused and in their original packaging.',
          ),
          _buildFaqItem(
            'How long does shipping take?',
            'Standard shipping typically takes 3-5 business days. Express shipping is available for 1-2 business day delivery.',
          ),
          _buildFaqItem(
            'Do you ship internationally?',
            'Yes, we ship to most countries. Shipping times and costs vary by location.',
          ),
          const SizedBox(height: 24),

          // Contact Support Section
          const Text(
            'Contact Support',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildContactOption(
            icon: Icons.chat_outlined,
            title: 'Live Chat',
            subtitle: 'Available 24/7',
            onTap: () {
              // TODO: Open live chat
            },
          ),
          _buildContactOption(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'Response within 24 hours',
            onTap: () {
              // TODO: Open email support
            },
          ),
          _buildContactOption(
            icon: Icons.phone_outlined,
            title: 'Phone Support',
            subtitle: 'Mon-Fri, 9AM-6PM',
            onTap: () {
              // TODO: Open phone support
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelpCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer, style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
