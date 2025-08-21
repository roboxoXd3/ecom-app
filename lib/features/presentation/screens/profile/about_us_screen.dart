import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App Logo and Version
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    // Apply theme-aware color filter for dark mode visibility
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                    errorBuilder:
                        (context, error, stackTrace) => Icon(
                          Icons.shopping_bag,
                          size: 100,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Be Smart',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Company Description
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Our Story',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Be Smart is your one-stop destination for all your shopping needs. '
                    'We started with a simple mission: to make quality products accessible '
                    'to everyone, everywhere. Our journey began in 2023, and since then, '
                    'we\'ve been committed to providing the best shopping experience to our customers.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Mission and Vision
                  const Text(
                    'Our Mission',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMissionItem(
                    icon: Icons.thumb_up_outlined,
                    title: 'Quality First',
                    description:
                        'Providing high-quality products at competitive prices.',
                  ),
                  _buildMissionItem(
                    icon: Icons.security_outlined,
                    title: 'Secure Shopping',
                    description:
                        'Ensuring safe and secure transactions for all customers.',
                  ),
                  _buildMissionItem(
                    icon: Icons.support_agent_outlined,
                    title: '24/7 Support',
                    description:
                        'Always here to help with dedicated customer support.',
                  ),
                  const SizedBox(height: 24),

                  // Contact Information
                  const Text(
                    'Get in Touch',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    detail: 'support@shopnow.com',
                  ),
                  _buildContactItem(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    detail: '+1 234 567 890',
                  ),
                  _buildContactItem(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    detail: '123 Shopping Street, NY 10001, USA',
                  ),
                  const SizedBox(height: 24),

                  // Social Media Links
                  const Text(
                    'Follow Us',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialButton(Icons.facebook, 'Facebook'),
                      _buildSocialButton(
                        Icons.camera_alt_outlined,
                        'Instagram',
                      ),
                      _buildSocialButton(Icons.telegram, 'Twitter'),
                      _buildSocialButton(Icons.link, 'LinkedIn'),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(detail, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, String platform) {
    return InkWell(
      onTap: () {
        // TODO: Implement social media links
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 4),
          Text(platform, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
