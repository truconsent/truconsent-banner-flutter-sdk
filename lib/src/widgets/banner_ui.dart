/// BannerUI - Flutter banner UI widget
import 'package:flutter/material.dart' hide Banner;
import '../models/banner.dart' as models;
import 'modern_banner_header.dart';
import 'modern_purpose_card.dart';
import 'modern_banner_footer.dart';
import 'modern_banner_actions.dart';

class BannerUI extends StatelessWidget {
  final models.Banner banner;
  final String companyName;
  final String? logoUrl;
  final Function(String, String) onChangePurpose;
  final VoidCallback onRejectAll;
  final VoidCallback onConsentAll;
  final VoidCallback onAcceptSelected;
  final String? primaryColor;
  final String? secondaryColor;

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
    final finalSecondaryColor = settings?.secondaryColor ?? secondaryColor ?? '#555';
    final footerText = settings?.footerText ??
        'Review our [Privacy Policy] and [Transparency Centre], [DPO Details]. Use the [Rights Centre] anytime to withdraw consent, delete data, name a nominee, or raise a grievance.';
    final bannerTitle = settings?.bannerTitle;
    final disclaimerText = settings?.disclaimerText;
    final actionButtonText = settings?.actionButtonText ?? 'I Consent';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ModernBannerHeader(
            logoUrl: settings?.logoUrl ?? logoUrl,
            orgName: companyName,
            bannerTitle: bannerTitle,
            disclaimerText: disclaimerText,
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: banner.purposes
                  .map((p) => ModernPurposeCard(
                        purpose: p,
                        banner: banner,
                        onToggle: onChangePurpose,
                      ))
                  .toList(),
            ),
          ),
          ModernBannerFooter(
            footerText: footerText,
            orgName: companyName,
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
    );
  }
}

