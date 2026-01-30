/// ModernBannerFooter - Flutter banner footer widget
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class ModernBannerFooter extends StatelessWidget {
  final String footerText;
  final String orgName;

  const ModernBannerFooter({
    super.key,
    required this.footerText,
    required this.orgName,
  });

  String _processPlaceholder(String text) {
    return text.replaceAll('[Organization Name]', orgName);
  }

  List<TextSpan> _parseMarkdownLinks(String text) {
    final regex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final linkText = match.group(1)!;
      var url = match.group(2)!.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      spans.add(
        TextSpan(
          text: linkText,
          style: const TextStyle(
            color: Colors.purple,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final fontSize = isMobile ? 11.0 : 12.0;
    
    final processedText = _processPlaceholder(footerText);
    final spans = _parseMarkdownLinks(processedText);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.grey[700],
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

