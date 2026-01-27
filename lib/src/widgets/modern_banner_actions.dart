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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(color: Colors.grey[50]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: onRejectAll,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
            ),
            child: const Text(
              'Reject All',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onConsentAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: _parseColor(primaryColor),
            ),
            child: Text(actionButtonText ?? 'Accept All'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: isDisabled ? null : onAcceptSelected,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled ? Colors.grey : Colors.green,
            ),
            child: Text(dynamicButtonLabel),
          ),
        ],
      ),
    );
  }
}

