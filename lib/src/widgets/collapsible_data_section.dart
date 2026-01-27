/// CollapsibleDataSection - Flutter collapsible section widget
import 'package:flutter/material.dart';
import '../models/banner.dart';

class CollapsibleDataSection extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final bool isOpen;
  final VoidCallback onToggle;

  const CollapsibleDataSection({
    super.key,
    required this.title,
    required this.items,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$title (${items.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  isOpen ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((item) {
                    final name = item is DataElement || item is ProcessingActivity
                        ? item.name
                        : item.toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
      ],
    );
  }
}

