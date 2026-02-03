import 'package:flutter/material.dart' hide Banner;
import '../models/banner.dart' as models;
import 'modern_banner_header.dart';
import 'modern_purpose_card.dart';
import 'modern_banner_footer.dart';
import 'modern_banner_actions.dart';

/// Standard consent banner UI widget.
///
/// Displays a consent banner with purposes, data elements, and action buttons.
/// This widget is used for standard consent collection flows.
///
/// Example:
/// ```dart
/// BannerUI(
///   banner: bannerData,
///   companyName: 'My Company',
///   onChangePurpose: (purposeId, status) {
///     // Handle purpose status change
///   },
///   onRejectAll: () => print('Rejected all'),
///   onConsentAll: () => print('Consented all'),
///   onAcceptSelected: () => print('Accepted selected'),
/// )
/// ```
class BannerUI extends StatelessWidget {
  /// Banner configuration data from the API
  final models.Banner banner;
  
  /// Company name to display in the banner
  final String companyName;
  
  /// Optional company logo URL
  final String? logoUrl;
  
  /// Callback when a purpose's consent status changes
  /// Parameters: (purposeId, newStatus)
  final Function(String, String) onChangePurpose;
  
  /// Callback when user clicks "Reject All"
  final VoidCallback onRejectAll;
  
  /// Callback when user clicks "Consent All"
  final VoidCallback onConsentAll;
  
  /// Callback when user clicks "Accept Selected"
  final VoidCallback onAcceptSelected;
  
  /// Optional primary color for buttons (hex format, e.g., '#3b82f6')
  final String? primaryColor;
  
  /// Optional secondary color (hex format)
  final String? secondaryColor;

  /// Creates a BannerUI widget.
  const BannerUI({
    super.key,
    required this.banner,
    required this.companyName,
    this.logoUrl,
    required this.onChangePurpose,
    required this.onRejectAll,
    required this.onConsentAll,
    required this.onAcceptSelected,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final settings = banner.bannerSettings;
    final finalPrimaryColor = settings?.primaryColor ?? primaryColor ?? '#3b82f6';
    final footerText = settings?.footerText ??
        'Review our [Privacy Policy] and [Transparency Centre], [DPO Details]. Use the [Rights Centre] anytime to withdraw consent, delete data, name a nominee, or raise a grievance.';
    final bannerTitle = settings?.bannerTitle;
    final disclaimerText = settings?.disclaimerText;
    final actionButtonText = settings?.actionButtonText ?? 'I Consent';

    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: ModernBannerHeader(
              logoUrl: settings?.logoUrl ?? logoUrl,
              orgName: companyName,
              bannerTitle: bannerTitle,
              disclaimerText: disclaimerText,
            ),
          ),
          
          // Purposes Section
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: isMobile ? 16 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (banner.purposes.isNotEmpty)
                  Text(
                    'Consent Preferences',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                if (banner.purposes.isNotEmpty)
                  SizedBox(height: isMobile ? 12 : 16),
                ...banner.purposes.map((p) => Padding(
                  padding: EdgeInsets.only(bottom: isMobile ? 10 : 12),
                  child: ModernPurposeCard(
                    purpose: p,
                    banner: banner,
                    onToggle: onChangePurpose,
                  ),
                )).toList(),
              ],
            ),
          ),

          // Footer Section
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 24,
                    vertical: isMobile ? 12 : 16,
                  ),
                  child: ModernBannerFooter(
                    footerText: footerText,
                    orgName: companyName,
                  ),
                ),
                ModernBannerActions(
                  onRejectAll: onRejectAll,
                  onConsentAll: onConsentAll,
                  onAcceptSelected: onAcceptSelected,
                  purposes: banner.purposes,
                  actionButtonText: actionButtonText,
                  primaryColor: finalPrimaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
