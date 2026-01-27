/// ModernBannerActions - Flutter banner actions widget
import 'package:flutter/material.dart';
import '../models/banner.dart';
import '../services/consent_manager.dart';

class ModernBannerActions extends StatelessWidget {
  final VoidCallback onRejectAll;
  final VoidCallback onConsentAll;
  final VoidCallback onAcceptSelected;
  final List<Purpose> purposes;
  final String? actionButtonText;
  final String? primaryColor;

  const ModernBannerActions({
    super.key,
    required this.onRejectAll,
    required this.onConsentAll,
    required this.onAcceptSelected,
    required this.purposes,
    this.actionButtonText,
    this.primaryColor,
  });

  Color _parseColor(String? colorString) {
    if (colorString == null) return const Color(0xFF7030bc);
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF7030bc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anyOptionalAccepted = hasOptionalAccepted(purposes);
    final hasMandatory = hasMandatoryPurposes(purposes);
    final isDisabled = !anyOptionalAccepted && !hasMandatory;

    final dynamicButtonLabel = anyOptionalAccepted
        ? 'Accept Selected'
        : 'Accept Only Necessary';

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isSmallMobile = screenWidth < 400;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(color: Colors.grey[50]),
      child: isSmallMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: onRejectAll,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Reject All',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onConsentAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _parseColor(primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(actionButtonText ?? 'Accept All'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: isDisabled ? null : onAcceptSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDisabled ? Colors.grey : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(dynamicButtonLabel),
                ),
              ],
            )
          : Wrap(
              alignment: WrapAlignment.end,
              spacing: isMobile ? 8 : 16,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  onPressed: onRejectAll,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 32,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Reject All',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
                ElevatedButton(
                  onPressed: onConsentAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _parseColor(primaryColor),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 32,
                      vertical: 10,
                    ),
                  ),
                  child: Text(actionButtonText ?? 'Accept All'),
                ),
                ElevatedButton(
                  onPressed: isDisabled ? null : onAcceptSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDisabled ? Colors.grey : Colors.green,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 32,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    dynamicButtonLabel,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }
}

