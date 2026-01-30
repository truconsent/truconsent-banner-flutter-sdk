/// ModernPurposeCard - Flutter purpose card widget
import 'package:flutter/material.dart' hide Banner;
import '../models/banner.dart' as models;
import 'collapsible_data_section.dart';

class ModernPurposeCard extends StatefulWidget {
  final models.Purpose purpose;
  final models.Banner banner;
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
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    
    final isAccepted = widget.purpose.consented == 'accepted';
    final expiryLabel = widget.purpose.expiryLabel ?? widget.purpose.expiryPeriod;
    final dataElements = widget.purpose.dataElements ?? [];
    final processingActivities = widget.purpose.processingActivities ?? [];
    final legalEntities = widget.purpose.legalEntities ?? [];
    final tools = widget.purpose.tools ?? [];

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isAccepted ? Colors.green[300]! : Colors.grey[300]!,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isAccepted ? Colors.green[50] : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Purpose Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with Mandatory badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.purpose.name,
                            style: TextStyle(
                              fontSize: isMobile ? 15 : 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900],
                            ),
                          ),
                        ),
                        if (widget.purpose.isMandatory)
                          Container(
                            margin: EdgeInsets.only(left: isMobile ? 6 : 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 6 : 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              border: Border.all(
                                color: Colors.red[400]!,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Mandatory',
                              style: TextStyle(
                                fontSize: isMobile ? 9 : 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    // Description
                    Text(
                      widget.purpose.description,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    // Expiry info
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        border: Border.all(color: Colors.amber[200]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Expires: ',
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 12,
                          color: Colors.amber[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              // Toggle Switch
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.scale(
                    scale: isMobile ? 0.8 : 1.0,
                    child: Switch(
                      value: isAccepted,
                      onChanged: (value) {
                        widget.onToggle(
                          widget.purpose.id,
                          value ? 'accepted' : 'declined',
                        );
                      },
                      activeColor: Colors.green[600],
                      inactiveThumbColor: Colors.grey[400],
                    ),
                  ),
                  Text(
                    isAccepted ? 'Accepted' : 'Declined',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.w600,
                      color: isAccepted
                          ? Colors.green[700]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Data Elements Section
          if (dataElements.isNotEmpty) ...[
            SizedBox(height: isMobile ? 10 : 12),
            CollapsibleDataSection(
              title: 'Data Elements',
              items: dataElements,
              isOpen: _openSection == 'data_elements',
              onToggle: () => _toggleSection('data_elements'),
            ),
          ],

          // Data Processors Section
          if (legalEntities.isNotEmpty || tools.isNotEmpty) ...[
            SizedBox(height: isMobile ? 8 : 12),
            Divider(
              height: 1,
              color: Colors.grey[200],
              thickness: 1,
            ),
            InkWell(
              onTap: () => _toggleSection('data_processors'),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Data Processors',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Icon(
                      _openSection == 'data_processors'
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: isMobile ? 20 : 24,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
            if (_openSection == 'data_processors')
              Padding(
                padding: EdgeInsets.only(top: isMobile ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (legalEntities.isNotEmpty) ...[
                      Text(
                        'Legal Entities ()',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      Wrap(
                        spacing: isMobile ? 6 : 8,
                        runSpacing: isMobile ? 6 : 8,
                        children: legalEntities
                            .map((e) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 8 : 10,
                                    vertical: isMobile ? 4 : 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    e.name,
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 13,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      SizedBox(height: isMobile ? 10 : 12),
                    ],
                    if (tools.isNotEmpty) ...[
                      Text(
                        'Tools ()',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      Wrap(
                        spacing: isMobile ? 6 : 8,
                        runSpacing: isMobile ? 6 : 8,
                        children: tools
                            .map((t) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 8 : 10,
                                    vertical: isMobile ? 4 : 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[50],
                                    border: Border.all(
                                      color: Colors.purple[200]!,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    t.name,
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 13,
                                      color: Colors.purple[900],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
          ],

          // Processing Activities Section
          if (processingActivities.isNotEmpty) ...[
            SizedBox(height: isMobile ? 8 : 12),
            CollapsibleDataSection(
              title: 'Processing Activities',
              items: processingActivities,
              isOpen: _openSection == 'processing_activities',
              onToggle: () => _toggleSection('processing_activities'),
            ),
          ],
        ],
      ),
    );
  }
}
