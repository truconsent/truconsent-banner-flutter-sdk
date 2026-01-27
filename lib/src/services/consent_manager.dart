/// ConsentManager - Consent state management for Flutter
import '../models/banner.dart';

/// Update a single purpose's consent status in the purposes list
List<Purpose> updatePurposeStatus(
  List<Purpose> purposes,
  String purposeId,
  String newStatus,
) {
  return purposes.map((p) {
    if (p.id == purposeId) {
      return Purpose(
        id: p.id,
        name: p.name,
        description: p.description,
        isMandatory: p.isMandatory,
        consented: newStatus,
        expiryPeriod: p.expiryPeriod,
        expiryLabel: p.expiryLabel,
        dataElements: p.dataElements,
        processingActivities: p.processingActivities,
        legalEntities: p.legalEntities,
        tools: p.tools,
      );
    }
    return p;
  }).toList();
}

/// Automatically accept all mandatory purposes while keeping user's selections for optional ones
List<Purpose> acceptMandatoryPurposes(List<Purpose> purposes) {
  return purposes.map((p) {
    if (p.isMandatory) {
      return Purpose(
        id: p.id,
        name: p.name,
        description: p.description,
        isMandatory: p.isMandatory,
        consented: 'accepted',
        expiryPeriod: p.expiryPeriod,
        expiryLabel: p.expiryLabel,
        dataElements: p.dataElements,
        processingActivities: p.processingActivities,
        legalEntities: p.legalEntities,
        tools: p.tools,
      );
    }
    return p;
  }).toList();
}

/// Determine consent action based on purpose states
ConsentAction determineConsentAction(
  List<Purpose> purposes, [
  List<Purpose>? previousPurposes,
]) {
  if (purposes.isEmpty) {
    return ConsentAction.declined;
  }

  // Check for revocation (previously accepted, now declined)
  if (previousPurposes != null) {
    final hasRevocation = purposes.any((p) {
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

  // Check if all purposes are accepted
  final allAccepted = purposes.every((p) => p.consented == 'accepted');
  if (allAccepted) {
    return ConsentAction.approved;
  }

  // Check if all purposes are declined
  final allDeclined = purposes.every((p) => p.consented == 'declined');
  if (allDeclined) {
    return ConsentAction.declined;
  }

  // Mixed consent (partial)
  return ConsentAction.partialConsent;
}

/// Get all accepted purposes
List<Purpose> getAcceptedPurposes(List<Purpose> purposes) {
  return purposes.where((p) => p.consented == 'accepted').toList();
}

/// Get all declined purposes
List<Purpose> getDeclinedPurposes(List<Purpose> purposes) {
  return purposes.where((p) => p.consented == 'declined').toList();
}

/// Check if any optional purposes are accepted
bool hasOptionalAccepted(List<Purpose> purposes) {
  return purposes
      .where((p) => !p.isMandatory)
      .any((p) => p.consented == 'accepted');
}

/// Check if there are any mandatory purposes
bool hasMandatoryPurposes(List<Purpose> purposes) {
  return purposes.any((p) => p.isMandatory);
}

