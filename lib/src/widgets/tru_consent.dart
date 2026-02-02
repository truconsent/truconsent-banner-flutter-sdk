/// TruConsent - Auto-showing consent modal wrapper
///
/// Displays a modal popup immediately on mount with loading state.
/// The modal fetches banner data and shows consent UI.
///
/// This is a convenience wrapper around TruConsentModal that automatically
/// shows the modal when the widget is mounted.
import 'package:flutter/material.dart';
import 'tru_consent_modal.dart';
import '../models/banner.dart';

class TruConsent extends StatelessWidget {
  final String apiKey;
  final String organizationId;
  final String bannerId;
  final String userId;
  final String? apiBaseUrl;
  final String? logoUrl;
  final String companyName;
  final Function(ConsentAction)? onClose;

  const TruConsent({
    super.key,
    required this.apiKey,
    required this.organizationId,
    required this.bannerId,
    required this.userId,
    this.apiBaseUrl,
    this.logoUrl,
    this.companyName = 'Mars Company',
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-show modal on mount - TruConsentModal handles loading state internally
    return TruConsentModal(
      apiKey: apiKey,
      organizationId: organizationId,
      bannerId: bannerId,
      userId: userId,
      apiBaseUrl: apiBaseUrl,
      logoUrl: logoUrl,
      companyName: companyName,
      onClose: onClose,
    );
  }
}

