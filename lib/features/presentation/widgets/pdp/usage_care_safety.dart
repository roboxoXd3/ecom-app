import 'package:flutter/material.dart';

class UsageCareSafety extends StatelessWidget {
  final List<String> usageInstructions;
  final List<String> careInstructions;
  final List<String> safetyNotes;

  const UsageCareSafety({
    super.key,
    required this.usageInstructions,
    required this.careInstructions,
    required this.safetyNotes,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnyContent =
        usageInstructions.isNotEmpty ||
        careInstructions.isNotEmpty ||
        safetyNotes.isNotEmpty;

    if (!hasAnyContent) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usage, Care & Safety',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Usage Instructions
          if (usageInstructions.isNotEmpty)
            _buildExpandableSection(
              'Usage Instructions',
              usageInstructions,
              Icons.help_outline,
              Colors.blue,
            ),

          // Care Instructions
          if (careInstructions.isNotEmpty)
            _buildExpandableSection(
              'Care Instructions',
              careInstructions,
              Icons.cleaning_services,
              Colors.green,
            ),

          // Safety Notes
          if (safetyNotes.isNotEmpty)
            _buildExpandableSection(
              'Safety Notes',
              safetyNotes,
              Icons.warning_outlined,
              Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  items
                      .map((item) => _buildInstructionItem(item, color))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String instruction, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
