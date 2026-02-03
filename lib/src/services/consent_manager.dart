import '../models/banner.dart';

/// Updates a single purpose's consent status in the purposes list.
///
/// Returns a new list with the specified purpose's status updated.
///
/// Example:
/// ```dart
/// final updated = updatePurposeStatus(purposes, 'p1', 'accepted');
/// ```
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

/// Automatically accepts all mandatory purposes while keeping user's selections for optional ones.
///
/// Returns a new list with all mandatory purposes set to 'accepted'.
///
/// Example:
/// ```dart
/// final updated = acceptMandatoryPurposes(purposes);
/// ```
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

/// Determines the overall consent action based on purpose states.
///
/// Analyzes all purposes to determine if the user approved, declined, revoked,
/// or provided partial consent. Can also detect revocation by comparing with
/// previous purpose states.
///
/// Returns [ConsentAction.approved] if all purposes are accepted,
/// [ConsentAction.declined] if all are declined,
/// [ConsentAction.revoked] if any previously accepted purpose is now declined,
/// or [ConsentAction.partialConsent] for mixed states.
///
/// Example:
/// ```dart
/// final action = determineConsentAction(purposes);
/// ```
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

/// Returns a list of all purposes that have been accepted.
///
/// Example:
/// ```dart
/// final accepted = getAcceptedPurposes(purposes);
/// ```
List<Purpose> getAcceptedPurposes(List<Purpose> purposes) {
  return purposes.where((p) => p.consented == 'accepted').toList();
}

/// Returns a list of all purposes that have been declined.
///
/// Example:
/// ```dart
/// final declined = getDeclinedPurposes(purposes);
/// ```
List<Purpose> getDeclinedPurposes(List<Purpose> purposes) {
  return purposes.where((p) => p.consented == 'declined').toList();
}

/// Checks if any optional (non-mandatory) purposes have been accepted.
///
/// Returns `true` if at least one optional purpose is accepted.
///
/// Example:
/// ```dart
/// if (hasOptionalAccepted(purposes)) {
///   // User accepted some optional purposes
/// }
/// ```
bool hasOptionalAccepted(List<Purpose> purposes) {
  return purposes
      .where((p) => !p.isMandatory)
      .any((p) => p.consented == 'accepted');
}

/// Checks if there are any mandatory purposes in the list.
///
/// Returns `true` if at least one purpose is marked as mandatory.
///
/// Example:
/// ```dart
/// if (hasMandatoryPurposes(purposes)) {
///   // Banner contains mandatory purposes
/// }
/// ```
bool hasMandatoryPurposes(List<Purpose> purposes) {
  return purposes.any((p) => p.isMandatory);
}

