import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/support_controller.dart';

class HelpSupportScreen extends StatelessWidget {
  final supportController = Get.put(SupportController());

  HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: Obx(() {
        if (supportController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // FAQs Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...supportController.faqs.map((faq) {
              return _buildFaqItem(faq.question, faq.answer);
            }),
          ],
        );
      }),
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
}
