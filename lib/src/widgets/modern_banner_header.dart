/// ModernBannerHeader - Flutter banner header widget
import 'package:flutter/material.dart';

class ModernBannerHeader extends StatefulWidget {
  final String? logoUrl;
  final String orgName;
  final String? bannerTitle;
  final String? disclaimerText;

  const ModernBannerHeader({
    super.key,
    this.logoUrl,
    required this.orgName,
    this.bannerTitle,
    this.disclaimerText,
  });

  @override
  State<ModernBannerHeader> createState() => _ModernBannerHeaderState();
}

class _ModernBannerHeaderState extends State<ModernBannerHeader> {
  String _language = 'en';

  String _processPlaceholder(String? text) {
    return (text ?? '').replaceAll('[Organization Name]', widget.orgName);
  }

  String _getTitle() {
    final title = _processPlaceholder(widget.bannerTitle);
    if (title.isNotEmpty) {
      return title.replaceAll('{{companyName}}', widget.orgName);
    }
    return 'Consent by ${widget.orgName}';
  }

  String _getDisclaimer() {
    final disclaimer = _processPlaceholder(widget.disclaimerText);
    if (disclaimer.isNotEmpty) {
      return disclaimer.replaceAll('{{companyName}}', widget.orgName);
    }
    return 'You have the right to decline consents which you feel are not required by ${widget.orgName}';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final headerPadding = isMobile ? 16.0 : 24.0;
    final logoSize = isMobile ? 28.0 : 32.0;
    final titleFontSize = isMobile ? 16.0 : 20.0;
    final disclaimerPadding = isMobile ? 12.0 : 16.0;

    return Padding(
      padding: EdgeInsets.all(headerPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Logo and Language Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (widget.logoUrl != null) ...[
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(6),
                            child: Image.network(
                              widget.logoUrl!,
                              height: logoSize,
                              width: logoSize,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                        ],
                        Expanded(
                          child: Text(
                            _getTitle(),
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900],
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  PopupMenuButton<String>(
                    onSelected: (value) => setState(() => _language = value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'en', child: Text('English')),
                      const PopupMenuItem(value: 'ta', child: Text('தமிழ்')),
                      const PopupMenuItem(value: 'hi', child: Text('हिंदी')),
                    ],
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8 : 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _language == 'en'
                                ? 'English'
                                : _language == 'ta'
                                    ? 'தமிழ்'
                                    : 'हिंदी',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: isMobile ? 18 : 20,
                            color: Colors.grey[700],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 12 : 16),
            ],
          ),

          // Disclaimer Box with improved styling
          Container(
            padding: EdgeInsets.all(disclaimerPadding),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[300]!, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _getDisclaimer(),
              style: TextStyle(
                color: Colors.blue[900],
                fontSize: isMobile ? 12 : 14,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          SizedBox(height: isMobile ? 12 : 16),
          Divider(
            height: 1,
            color: Colors.grey[200],
            thickness: 1,
          ),
        ],
      ),
    );
  }
}

