import '../models/banner.dart';

/// Updates a single purpose's consent status in the purposes list.
List<Purpose> updatePurposeStatus(
  List<Purpose> purposes,
  String purposeId,
  String newStatus,
) {
  return purposes.map((p) {
    if (p.id == purposeId) {
      return p.copyWith(consented: newStatus);
    }
    return p;
  }).toList();
}

/// Automatically accepts all mandatory purposes while keeping user's selections for optional ones.
List<Purpose> acceptMandatoryPurposes(List<Purpose> purposes) {
  return purposes.map((p) {
    if (p.isMandatory) {
      return p.copyWith(consented: 'accepted');
    }
    return p;
  }).toList();
}

/// Normalizes a purpose by computing derived fields.
/// Fields: isLegitimate, isMandatory, legalBasis, withdrawable, isDynamic, initial consented.
Purpose normalizePurpose(Purpose p) {
  // Already computed in Purpose.fromJson; this re-derives if needed
  final isLegit = p.isLegitimate;
  final isMand = p.isMandatory;
  final freq = p.frequency;
  final basis = isLegit ? 'notice' : 'consent';
  final canWithdraw = !isLegit && freq == 'recurring';

  String consented = p.consented;
  if (isLegit || isMand) {
    consented = 'accepted';
  } else if (p.defaultSelection == 'all') {
    consented = 'accepted';
  } else if (p.defaultSelection == 'none') {
    consented = 'declined';
  } else {
    consented = 'declined';
  }

  return Purpose(
    id: p.id,
    name: p.name,
    description: p.description,
    isMandatory: isMand,
    isLegitimate: isLegit,
    consented: consented,
    expiryPeriod: p.expiryPeriod,
    expiryLabel: p.expiryLabel,
    dataElements: p.dataElements,
    processingActivities: p.processingActivities,
    legalEntities: p.legalEntities,
    tools: p.tools,
    legalBasis: basis,
    withdrawable: canWithdraw,
    isDynamic: p.isDynamic,
    frequency: freq,
    purposeType: p.purposeType,
    defaultSelection: p.defaultSelection,
  );
}

/// Normalizes and sorts a list of purposes by hierarchy:
/// Legitimate (1) > Necessary/Mandatory (2) > Recurring (3) > Optional (4)
List<Purpose> normalizePurposes(List<Purpose> purposes) {
  final normalized = purposes.map(normalizePurpose).toList();
  normalized.sort((a, b) {
    int rankA = _purposeRank(a);
    int rankB = _purposeRank(b);
    return rankA.compareTo(rankB);
  });
  return normalized;
}

int _purposeRank(Purpose p) {
  if (p.isLegitimate) return 1;
  if (p.isMandatory) return 2;
  if (p.frequency == 'recurring') return 3;
  return 4;
}

/// Detects the banner case based on purpose types.
BannerCase detectBannerCase(List<Purpose> purposes) {
  if (purposes.isEmpty) return BannerCase.normal;

  final hasNotice = purposes.any((p) => p.isLegitimate || p.legalBasis == 'notice');
  final hasConsent = purposes.any((p) => !p.isLegitimate && p.legalBasis == 'consent');

  if (hasNotice && hasConsent) return BannerCase.tabbed;
  if (hasNotice && !hasConsent) return BannerCase.noticeOnly;
  return BannerCase.normal;
}

/// Derives the full UI state for rendering.
UIState deriveUIState(List<Purpose> purposes) {
  final bannerCase = detectBannerCase(purposes);
  final noticePurposes = purposes.where((p) => p.isLegitimate || p.legalBasis == 'notice').toList();
  final consentPurposes = purposes.where((p) => !p.isLegitimate && p.legalBasis == 'consent').toList();
  final mandatoryConsentPurposes = consentPurposes.where((p) => p.isMandatory).toList();
  final optionalConsentPurposes = consentPurposes.where((p) => !p.isMandatory).toList();

  return UIState(
    noticeOnly: bannerCase == BannerCase.noticeOnly,
    consentOnly: bannerCase == BannerCase.normal,
    isHCase: mandatoryConsentPurposes.isNotEmpty,
    hasRequiredConsent: mandatoryConsentPurposes.isNotEmpty,
    bannerCase: bannerCase,
    noticePurposes: noticePurposes,
    consentPurposes: consentPurposes,
    mandatoryConsentPurposes: mandatoryConsentPurposes,
    optionalConsentPurposes: optionalConsentPurposes,
  );
}

/// Checks if any mandatory consent purpose is being declined.
/// Returns true if H-Case intercept should be triggered.
bool checkHCaseIntercept(List<Purpose> purposes) {
  return purposes.any((p) => p.isMandatory && !p.isLegitimate && p.consented != 'accepted');
}

/// Determines the overall consent action based on purpose states.
ConsentAction determineConsentAction(
  List<Purpose> purposes, [
  List<Purpose>? previousPurposes,
]) {
  if (purposes.isEmpty) {
    return ConsentAction.declined;
  }

  // Only consider consent (non-legitimate) purposes for action logic
  final consentPurposes = purposes.where((p) => !p.isLegitimate).toList();

  if (consentPurposes.isEmpty) {
    // All are notice purposes
    return ConsentAction.noticeShown;
  }

  if (previousPurposes != null) {
    final hasRevocation = consentPurposes.any((p) {
      final previous = previousPurposes.firstWhere(
        (prev) => prev.id == p.id,
        orElse: () => p,
      );
      return previous.consented == 'accepted' && p.consented == 'declined';
    });
    if (hasRevocation) {
      return ConsentAction.revoked;
    }
  }

  final allAccepted = consentPurposes.every((p) => p.consented == 'accepted');
  if (allAccepted) {
    return ConsentAction.approved;
  }

  final allDeclined = consentPurposes.every((p) => p.consented == 'declined');
  if (allDeclined) {
    return ConsentAction.declined;
  }

  return ConsentAction.partialConsent;
}

/// Returns a list of all purposes that have been accepted.
List<Purpose> getAcceptedPurposes(List<Purpose> purposes) {
  return purposes.where((p) => p.consented == 'accepted').toList();
}

/// Returns a list of all purposes that have been declined.
List<Purpose> getDeclinedPurposes(List<Purpose> purposes) {
  return purposes.where((p) => p.consented == 'declined').toList();
}

/// Checks if any optional (non-mandatory) purposes have been accepted.
bool hasOptionalAccepted(List<Purpose> purposes) {
  return purposes
      .where((p) => !p.isMandatory && !p.isLegitimate)
      .any((p) => p.consented == 'accepted');
}

/// Checks if there are any mandatory purposes in the list.
bool hasMandatoryPurposes(List<Purpose> purposes) {
  return purposes.any((p) => p.isMandatory && !p.isLegitimate);
}
