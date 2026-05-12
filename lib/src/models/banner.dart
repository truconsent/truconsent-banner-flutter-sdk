/// Banner model representing the consent banner configuration from TruConsent API.
///
/// Contains all banner data including purposes, data elements, processing activities,
/// and banner settings.

/// Enum representing the banner case based on purpose types.
enum BannerCase {
  /// Has both notice/legitimate AND consent purposes
  tabbed,
  /// Has only consent purposes
  normal,
  /// Has only legitimate/notice purposes
  noticeOnly,
}

/// Derived UI state for rendering the banner.
class UIState {
  final bool noticeOnly;
  final bool consentOnly;
  final bool isHCase;
  final bool hasRequiredConsent;
  final BannerCase bannerCase;
  final List<Purpose> noticePurposes;
  final List<Purpose> consentPurposes;
  final List<Purpose> mandatoryConsentPurposes;
  final List<Purpose> optionalConsentPurposes;

  UIState({
    required this.noticeOnly,
    required this.consentOnly,
    required this.isHCase,
    required this.hasRequiredConsent,
    required this.bannerCase,
    required this.noticePurposes,
    required this.consentPurposes,
    required this.mandatoryConsentPurposes,
    required this.optionalConsentPurposes,
  });
}

class Banner {
  final String bannerId;
  final String collectionPoint;
  final String version;
  final String title;
  final String expiryType;
  final Asset? asset;
  final List<Purpose> purposes;
  final List<DataElement>? dataElements;
  final List<LegalEntity>? legalEntities;
  final List<Tool>? tools;
  final List<ProcessingActivity>? processingActivities;
  final String? consentType;
  final CookieConfig? cookieConfig;
  final BannerSettings? bannerSettings;
  final Organization? organization;
  final String? organizationName;

  // Re-consent fields
  final bool reconsentMode;
  final String? reconsentCampaignId;
  final String? reconsentUiMode;
  final Map<String, dynamic>? versionDiff;
  final String? reconsentSource;
  final String? expiryReconsentRequestId;
  final String? consentStatus;

  Banner({
    required this.bannerId,
    required this.collectionPoint,
    required this.version,
    required this.title,
    required this.expiryType,
    this.asset,
    required this.purposes,
    this.dataElements,
    this.legalEntities,
    this.tools,
    this.processingActivities,
    this.consentType,
    this.cookieConfig,
    this.bannerSettings,
    this.organization,
    this.organizationName,
    this.reconsentMode = false,
    this.reconsentCampaignId,
    this.reconsentUiMode,
    this.versionDiff,
    this.reconsentSource,
    this.expiryReconsentRequestId,
    this.consentStatus,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      bannerId: json['banner_id'] ?? json['collection_point'] ?? '',
      collectionPoint: json['collection_point'] ?? '',
      version: json['version'] ?? '1',
      title: json['title'] ?? '',
      expiryType: json['expiry_type'] ?? 'active',
      asset: json['asset'] != null ? Asset.fromJson(json['asset']) : null,
      purposes: (json['purposes'] as List<dynamic>?)
              ?.map((p) => Purpose.fromJson(p))
              .toList() ??
          [],
      dataElements: (json['data_elements'] as List<dynamic>?)
          ?.map((e) => DataElement.fromJson(e))
          .toList(),
      legalEntities: (json['legal_entities'] as List<dynamic>?)
          ?.map((e) => LegalEntity.fromJson(e))
          .toList(),
      tools: (json['tools'] as List<dynamic>?)
          ?.map((t) => Tool.fromJson(t))
          .toList(),
      processingActivities: (json['processing_activities'] as List<dynamic>?)
          ?.map((a) => ProcessingActivity.fromJson(a))
          .toList(),
      consentType: json['consent_type'],
      cookieConfig: json['cookie_config'] != null
          ? CookieConfig.fromJson(json['cookie_config'])
          : null,
      bannerSettings: json['banner_settings'] != null
          ? BannerSettings.fromJson(json['banner_settings'])
          : null,
      organization: json['organization'] != null
          ? Organization.fromJson(json['organization'])
          : null,
      organizationName: json['organization_name'],
      reconsentMode: json['reconsent_mode'] == true,
      reconsentCampaignId: json['reconsent_campaign_id'],
      reconsentUiMode: json['reconsent_ui_mode'],
      versionDiff: json['version_diff'] as Map<String, dynamic>?,
      reconsentSource: json['reconsent_source'],
      expiryReconsentRequestId: json['expiry_reconsent_request_id'],
      consentStatus: json['consent_status'] ?? json['data']?['consentStatus'],
    );
  }
}

/// Represents a consent purpose in the banner.
class Purpose {
  /// Unique identifier for the purpose
  final String id;

  /// Display name of the purpose
  final String name;

  /// Description of what this purpose entails
  final String description;

  /// Whether this purpose is mandatory (cannot be declined)
  final bool isMandatory;

  /// Whether this purpose is legitimate interest (notice basis)
  final bool isLegitimate;

  /// Current consent status: 'accepted', 'declined', 'shown', or 'pending'
  final String consented;

  /// Expiry period for the consent (e.g., '1 Year')
  final String expiryPeriod;

  /// Optional human-readable expiry label
  final String? expiryLabel;

  /// Associated data elements for this purpose
  final List<DataElement>? dataElements;

  /// Associated processing activities
  final List<ProcessingActivity>? processingActivities;

  /// Associated legal entities
  final List<LegalEntity>? legalEntities;

  /// Associated tools/technologies
  final List<Tool>? tools;

  /// Legal basis: 'consent' or 'notice'
  final String legalBasis;

  /// Whether consent can be withdrawn (non-legitimate, recurring)
  final bool withdrawable;

  /// Whether this is a dynamic purpose
  final bool isDynamic;

  /// Frequency: 'recurring', 'one_time', etc.
  final String? frequency;

  /// Purpose type: 'consent' or 'legitimate_interest'
  final String? purposeType;

  /// Default selection: 'all', 'none', 'mandatory_only'
  final String? defaultSelection;

  Purpose({
    required this.id,
    required this.name,
    required this.description,
    required this.isMandatory,
    this.isLegitimate = false,
    required this.consented,
    required this.expiryPeriod,
    this.expiryLabel,
    this.dataElements,
    this.processingActivities,
    this.legalEntities,
    this.tools,
    this.legalBasis = 'consent',
    this.withdrawable = false,
    this.isDynamic = false,
    this.frequency,
    this.purposeType,
    this.defaultSelection,
  });

  factory Purpose.fromJson(Map<String, dynamic> json) {
    final isLegit = json['is_legitimate'] == true;
    final isMand = json['is_mandatory'] == true;
    final freq = json['frequency'] as String?;
    final basis = isLegit ? 'notice' : 'consent';
    final canWithdraw = !isLegit && freq == 'recurring';
    final isDyn = json['is_dynamic'] == true;
    final defSel = json['default_selection'] as String?;

    String initialConsented;
    if (isLegit || isMand) {
      initialConsented = 'accepted';
    } else if (defSel == 'all') {
      initialConsented = 'accepted';
    } else {
      initialConsented = 'declined';
    }

    return Purpose(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isMandatory: isMand,
      isLegitimate: isLegit,
      consented: json['consented'] ?? initialConsented,
      expiryPeriod: json['expiry_period'] ?? '',
      expiryLabel: json['expiry_label'],
      dataElements: (json['data_elements'] as List<dynamic>?)
          ?.map((e) => DataElement.fromJson(e))
          .toList(),
      processingActivities: (json['processing_activities'] as List<dynamic>?)
          ?.map((a) => ProcessingActivity.fromJson(a))
          .toList(),
      legalEntities: (json['legal_entities'] as List<dynamic>?)
          ?.map((e) => LegalEntity.fromJson(e))
          .toList(),
      tools: (json['tools'] as List<dynamic>?)
          ?.map((t) => Tool.fromJson(t))
          .toList(),
      legalBasis: basis,
      withdrawable: canWithdraw,
      isDynamic: isDyn,
      frequency: freq,
      purposeType: json['purpose_type'] as String?,
      defaultSelection: defSel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purposeId': id,
      'version': 'v1.0',
      'consented': isLegitimate ? 'shown' : consented,
      'purpose_type': isLegitimate ? 'legitimate_interest' : 'consent',
      'is_mandatory': isMandatory,
    };
  }

  /// Copy with updated consent status
  Purpose copyWith({String? consented}) {
    return Purpose(
      id: id,
      name: name,
      description: description,
      isMandatory: isMandatory,
      isLegitimate: isLegitimate,
      consented: consented ?? this.consented,
      expiryPeriod: expiryPeriod,
      expiryLabel: expiryLabel,
      dataElements: dataElements,
      processingActivities: processingActivities,
      legalEntities: legalEntities,
      tools: tools,
      legalBasis: legalBasis,
      withdrawable: withdrawable,
      isDynamic: isDynamic,
      frequency: frequency,
      purposeType: purposeType,
      defaultSelection: defaultSelection,
    );
  }
}

/// Represents a data element (type of personal data) collected.
class DataElement {
  final String id;
  final String name;
  final String? description;
  final String? displayId;

  DataElement({
    required this.id,
    required this.name,
    this.description,
    this.displayId,
  });

  factory DataElement.fromJson(Map<String, dynamic> json) {
    return DataElement(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      displayId: json['display_id'],
    );
  }
}

/// Represents a legal entity involved in data processing.
class LegalEntity {
  final String id;
  final String name;
  final String? description;
  final String? displayId;

  LegalEntity({
    required this.id,
    required this.name,
    this.description,
    this.displayId,
  });

  factory LegalEntity.fromJson(Map<String, dynamic> json) {
    return LegalEntity(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      displayId: json['display_id'],
    );
  }
}

/// Represents a tool or technology used in data processing.
class Tool {
  final String id;
  final String name;
  final String? description;
  final String? displayId;

  Tool({
    required this.id,
    required this.name,
    this.description,
    this.displayId,
  });

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      displayId: json['display_id'],
    );
  }
}

/// Represents a processing activity performed on personal data.
class ProcessingActivity {
  final String id;
  final String name;
  final String? description;
  final String? displayId;

  ProcessingActivity({
    required this.id,
    required this.name,
    this.description,
    this.displayId,
  });

  factory ProcessingActivity.fromJson(Map<String, dynamic> json) {
    return ProcessingActivity(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      displayId: json['display_id'],
    );
  }
}

/// Represents an asset associated with the banner.
class Asset {
  final String id;
  final String name;
  final String? description;
  final String? assetType;

  Asset({
    required this.id,
    required this.name,
    this.description,
    this.assetType,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      assetType: json['asset_type'],
    );
  }
}

/// Configuration for cookie consent.
class CookieConfig {
  final List<Cookie>? cookies;
  final List<String>? selectedDataElementIds;
  final List<String>? selectedProcessingActivityIds;

  CookieConfig({
    this.cookies,
    this.selectedDataElementIds,
    this.selectedProcessingActivityIds,
  });

  factory CookieConfig.fromJson(Map<String, dynamic> json) {
    return CookieConfig(
      cookies: (json['cookies'] as List<dynamic>?)
          ?.map((c) => Cookie.fromJson(c))
          .toList(),
      selectedDataElementIds:
          (json['selected_data_element_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList(),
      selectedProcessingActivityIds:
          (json['selected_processing_activity_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList(),
    );
  }
}

/// Represents a cookie definition in cookie consent configuration.
class Cookie {
  final String? id;
  final String? name;
  final String? category;
  final String? domain;
  final String? expiry;

  Cookie({
    this.id,
    this.name,
    this.category,
    this.domain,
    this.expiry,
  });

  factory Cookie.fromJson(Map<String, dynamic> json) {
    return Cookie(
      id: json['id']?.toString(),
      name: json['name'],
      category: json['category'],
      domain: json['domain'],
      expiry: json['expiry'],
    );
  }
}

/// Banner display settings and customization options.
class BannerSettings {
  final String? fontType;
  final String? fontSize;
  final String? primaryColor;
  final String? secondaryColor;
  final String? actionButtonText;
  final String? warningText;
  final String? logoUrl;
  final String? bannerTitle;
  final String? disclaimerText;
  final String? footerText;
  final bool? showPurposes;

  // H-Case settings
  final String? hCaseLoggingStrategy;
  final String? hCaseWarningMessage;
  final String? hCaseProceedButtonText;
  final String? hCaseBackButtonText;
  final String? hCaseProceedButtonColor;
  final String? hCaseBackButtonColor;

  // Default selection
  final String? defaultSelection;

  BannerSettings({
    this.fontType,
    this.fontSize,
    this.primaryColor,
    this.secondaryColor,
    this.actionButtonText,
    this.warningText,
    this.logoUrl,
    this.bannerTitle,
    this.disclaimerText,
    this.footerText,
    this.showPurposes,
    this.hCaseLoggingStrategy,
    this.hCaseWarningMessage,
    this.hCaseProceedButtonText,
    this.hCaseBackButtonText,
    this.hCaseProceedButtonColor,
    this.hCaseBackButtonColor,
    this.defaultSelection,
  });

  factory BannerSettings.fromJson(Map<String, dynamic> json) {
    return BannerSettings(
      fontType: json['font_type'],
      fontSize: json['font_size'],
      primaryColor: json['primary_color'],
      secondaryColor: json['secondary_color'],
      actionButtonText: json['action_button_text'],
      warningText: json['warning_text'],
      logoUrl: json['logo_url'],
      bannerTitle: json['banner_title'],
      disclaimerText: json['disclaimer_text'],
      footerText: json['footer_text'],
      showPurposes: json['show_purposes'],
      hCaseLoggingStrategy: json['h_case_logging_strategy'],
      hCaseWarningMessage: json['h_case_warning_message'],
      hCaseProceedButtonText: json['h_case_proceed_button_text'],
      hCaseBackButtonText: json['h_case_back_button_text'],
      hCaseProceedButtonColor: json['h_case_proceed_button_color'],
      hCaseBackButtonColor: json['h_case_back_button_color'],
      defaultSelection: json['default_selection'],
    );
  }
}

/// Represents the organization that owns the consent banner.
class Organization {
  final String name;
  final String? legalName;
  final String? tradeName;
  final String? logoUrl;

  Organization({
    required this.name,
    this.legalName,
    this.tradeName,
    this.logoUrl,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      name: json['name'] ?? '',
      legalName: json['legal_name'],
      tradeName: json['trade_name'],
      logoUrl: json['logo_url'],
    );
  }
}

/// Enum representing the user's consent action.
enum ConsentAction {
  approved,
  declined,
  noAction,
  revoked,
  partialConsent,
  noticeShown,
}

extension ConsentActionExtension on ConsentAction {
  String get value {
    switch (this) {
      case ConsentAction.approved:
        return 'Approved';
      case ConsentAction.declined:
        return 'Declined';
      case ConsentAction.noAction:
        return 'No Action';
      case ConsentAction.revoked:
        return 'Revoked';
      case ConsentAction.partialConsent:
        return 'Partially Consented';
      case ConsentAction.noticeShown:
        return 'notice_shown';
    }
  }
}
