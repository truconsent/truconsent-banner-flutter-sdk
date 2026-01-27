/// ModernBannerHeader - Flutter banner header widget
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    return title.isNotEmpty
        ? title
        : Intl.message('Consent by {{companyName}}',
            name: 'consent_by', args: [widget.orgName]);
  }

  String _getDisclaimer() {
    final disclaimer = _processPlaceholder(widget.disclaimerText);
    return disclaimer.isNotEmpty
        ? disclaimer
        : Intl.message(
            'You have the right to decline consents which you feel are not required by {{companyName}}',
            name: 'decline_rights',
            args: [widget.orgName]);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (widget.logoUrl != null) ...[
                      Image.network(
                        widget.logoUrl!,
                        height: 32,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Text(
                        _getTitle(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => setState(() => _language = value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'en', child: Text('English')),
                  const PopupMenuItem(value: 'ta', child: Text('தமிழ்')),
                  const PopupMenuItem(value: 'hi', child: Text('हिंदी')),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_language == 'en'
                        ? 'English'
                        : _language == 'ta'
                            ? 'தமிழ்'
                            : 'हिंदी'),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getDisclaimer(),
              style: TextStyle(color: Colors.blue[800]),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }
}

