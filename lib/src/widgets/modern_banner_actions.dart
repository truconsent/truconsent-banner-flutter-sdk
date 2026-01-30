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
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 380;

    final primaryButtonColor = _parseColor(primaryColor);
    final accentColor = Color.fromARGB(255, 255, 127, 38);  // Orange

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: isSmallMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Reject All Button
                OutlinedButton(
                  onPressed: onRejectAll,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: accentColor,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Reject All',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Accept All Button
                ElevatedButton(
                  onPressed: onConsentAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryButtonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    actionButtonText ?? 'Accept All',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Accept Selected Button
                ElevatedButton(
                  onPressed: isDisabled ? null : onAcceptSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDisabled ? Colors.grey[300] : Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    dynamicButtonLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accept All Button (Primary - Full Width)
                ElevatedButton(
                  onPressed: onConsentAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryButtonColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 28,
                      vertical: isMobile ? 13 : 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    actionButtonText ?? 'Accept All',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 12),
                // Secondary buttons (Reject & Accept Selected)
                Row(
                  children: [
                    // Reject All Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRejectAll,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: accentColor,
                            width: 1.5,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Reject All',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    // Accept Selected Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDisabled ? null : onAcceptSelected,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDisabled ? Colors.grey[300] : Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          dynamicButtonLabel,
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

