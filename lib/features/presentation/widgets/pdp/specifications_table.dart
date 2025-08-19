import 'package:flutter/material.dart';
import '../../../data/models/product_model.dart';
import '../../../../core/theme/app_theme.dart';

class SpecificationsTable extends StatefulWidget {
  final List<ProductSpec> specifications;

  const SpecificationsTable({super.key, required this.specifications});

  @override
  State<SpecificationsTable> createState() => _SpecificationsTableState();
}

class _SpecificationsTableState extends State<SpecificationsTable> {
  bool _isExpanded = false;
  static const int _previewRowCount = 4;

  @override
  Widget build(BuildContext context) {
    if (widget.specifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final allRows = widget.specifications.expand((spec) => spec.rows).toList();

    if (allRows.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayRows =
        _isExpanded ? allRows : allRows.take(_previewRowCount).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Specification rows
                ...displayRows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final isLast = index == displayRows.length - 1;

                  return Container(
                    decoration: BoxDecoration(
                      color: index.isEven ? Colors.grey[50] : Colors.white,
                      border:
                          isLast
                              ? null
                              : Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              row.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Text(
                              row.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // View All/Less button
          if (allRows.length > _previewRowCount) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'View Less' : 'View All Specifications',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Grouped specifications (if we want to show them grouped)
          if (_isExpanded && widget.specifications.length > 1) ...[
            const SizedBox(height: 16),
            ...widget.specifications
                .map((spec) => _buildSpecGroup(spec))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecGroup(ProductSpec spec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.group,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children:
                spec.rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final isLast = index == spec.rows.length - 1;

                  return Container(
                    decoration: BoxDecoration(
                      color: index.isEven ? Colors.grey[50] : Colors.white,
                      border:
                          isLast
                              ? null
                              : Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              row.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Text(
                              row.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
