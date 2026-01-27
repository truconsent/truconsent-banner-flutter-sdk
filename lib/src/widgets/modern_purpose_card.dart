/// ModernPurposeCard - Flutter purpose card widget
import 'package:flutter/material.dart';
import '../models/banner.dart';
import 'collapsible_data_section.dart';

class ModernPurposeCard extends StatefulWidget {
  final Purpose purpose;
  final Banner banner;
  final Function(String, String) onToggle;

  const ModernPurposeCard({
    super.key,
    required this.purpose,
    required this.banner,
    required this.onToggle,
  });

  @override
  State<ModernPurposeCard> createState() => _ModernPurposeCardState();
}

class _ModernPurposeCardState extends State<ModernPurposeCard> {
  String? _openSection;

  void _toggleSection(String section) {
    setState(() {
      _openSection = _openSection == section ? null : section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAccepted = widget.purpose.consented == 'accepted';
    final expiryLabel = widget.purpose.expiryLabel ?? widget.purpose.expiryPeriod;
    final dataElements = widget.purpose.dataElements ?? [];
    final processingActivities = widget.purpose.processingActivities ?? [];
    final legalEntities = widget.purpose.legalEntities ?? [];
    final tools = widget.purpose.tools ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.purpose.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.purpose.isMandatory)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Mandatory',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.purpose.description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Expiry: $expiryLabel',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Accept',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isAccepted ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isAccepted,
                        onChanged: (value) {
                          widget.onToggle(
                            widget.purpose.id,
                            value ? 'accepted' : 'declined',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (dataElements.isNotEmpty)
            CollapsibleDataSection(
              title: 'Data Elements',
              items: dataElements,
              isOpen: _openSection == 'data_elements',
              onToggle: () => _toggleSection('data_elements'),
            ),
          if (legalEntities.isNotEmpty || tools.isNotEmpty)
            Column(
              children: [
                const Divider(),
                InkWell(
                  onTap: () => _toggleSection('data_processors'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Data Processors',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          _openSection == 'data_processors'
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_openSection == 'data_processors')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (legalEntities.isNotEmpty) ...[
                          Text(
                            'Legal Entities (${legalEntities.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: legalEntities
                                .map((e) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        e.name,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (tools.isNotEmpty) ...[
                          Text(
                            'Tools (${tools.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tools
                                .map((t) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        t.name,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          if (processingActivities.isNotEmpty)
            CollapsibleDataSection(
              title: 'Processing Activities',
              items: processingActivities,
              isOpen: _openSection == 'processing_activities',
              onToggle: () => _toggleSection('processing_activities'),
            ),
        ],
      ),
    );
  }
}

