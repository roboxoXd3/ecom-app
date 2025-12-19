import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
                    'Welcome to Be Smart, your all-in-one online mall designed to make shopping smarter, easier, and more exciting!\n\n'
                    'At Be Smart, we started as a fashion-forward brand, known for our premium-quality clothing and trendsetting styles. Our boutique collection brings you the best in fashion — from casual to classy, simple to standout — carefully selected to help you express your true style with confidence.\n\n'
                    'But we didn\'t stop there. We\'ve grown beyond fashion to become a complete online marketplace, where you can find almost everything you need — from fashion wear and accessories to lifestyle products and everyday essentials — all in one trusted place.\n\n'
                    'We believe in quality, convenience, and customer satisfaction. Every item we showcase is chosen with care to ensure that when you shop with Be Smart, you\'re getting real value for your money.\n\n'
                    'Whether you\'re refreshing your wardrobe, shopping for a gift, or browsing for something unique, Be Smart is here to give you a smarter shopping experience — where quality meets affordability.\n\n'
                    'Be Smart. Shop Smart. Live Smart.',
                    style: TextStyle(fontSize: 16, height: 1.5),
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
                    context: context,
                    icon: Icons.email_outlined,
                    title: 'Email',
                    detail: 'support@xbesmart.com',
                    onTap: () => _launchEmail(context),
                  ),
                  _buildContactItem(
                    context: context,
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    detail: '07018688881',
                    onTap: () => _launchPhone(context),
                  ),
                  _buildContactItem(
                    context: context,
                    icon: Icons.chat_outlined,
                    title: 'WhatsApp',
                    detail: '+2347018688881',
                    onTap: () => _launchWhatsApp(context),
                  ),
                  _buildContactItem(
                    context: context,
                    icon: Icons.location_on_outlined,
                    title: 'Head Office',
                    detail: 'Shop 38C/B Asaba Development Mall, Asaba, Delta State, Nigeria',
                    onTap: null,
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
                      _buildSocialButton(
                        context: context,
                        icon: Icons.facebook,
                        platform: 'Facebook',
                        url: 'https://facebook.com/besmartworld',
                      ),
                      _buildSocialButton(
                        context: context,
                        icon: Icons.camera_alt_outlined,
                        platform: 'Instagram',
                        url: 'https://instagram.com/besmartcollections',
                      ),
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String detail,
    VoidCallback? onTap,
  }) {
    final widget = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(detail, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: widget,
      );
    }
    return widget;
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required IconData icon,
    required String platform,
    required String url,
  }) {
    return InkWell(
      onTap: () => _launchSocialMedia(context, url),
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

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri.parse('mailto:support@xbesmart.com');
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.platformDefault);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email app.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri.parse('tel:07018688881');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.platformDefault);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open phone dialer.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/2347018688881');
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchSocialMedia(BuildContext context, String url) async {
    final Uri socialUri = Uri.parse(url);
    try {
      if (await canLaunchUrl(socialUri)) {
        await launchUrl(socialUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open social media page.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
