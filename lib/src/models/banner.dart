/// Banner model representing the consent banner configuration from TruConsent API.
///
/// Contains all banner data including purposes, data elements, processing activities,
/// and banner settings.
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
    );
  }
}

/// Represents a consent purpose in the banner.
///
/// A purpose defines what data processing activity the user is consenting to.
/// Each purpose can be mandatory or optional, and contains associated data
/// elements, processing activities, legal entities, and tools.
class Purpose {
  /// Unique identifier for the purpose
  final String id;
  
  /// Display name of the purpose
  final String name;
  
  /// Description of what this purpose entails
  final String description;
  
  /// Whether this purpose is mandatory (cannot be declined)
  final bool isMandatory;
  
  /// Current consent status: 'accepted', 'declined', or 'pending'
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

  Purpose({
    required this.id,
    required this.name,
    required this.description,
    required this.isMandatory,
    required this.consented,
    required this.expiryPeriod,
    this.expiryLabel,
    this.dataElements,
    this.processingActivities,
    this.legalEntities,
    this.tools,
  });

  factory Purpose.fromJson(Map<String, dynamic> json) {
    return Purpose(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isMandatory: json['is_mandatory'] ?? false,
      consented: json['consented'] ?? 'declined',
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_mandatory': isMandatory,
      'consented': consented,
      'expiry_period': expiryPeriod,
      'expiry_label': expiryLabel,
    };
  }
}

/// Represents a data element (type of personal data) collected.
///
/// Data elements define what types of personal information are processed
/// for a given purpose (e.g., email, phone number, location).
class DataElement {
  /// Unique identifier for the data element
  final String id;
  
  /// Display name of the data element
  final String name;
  
  /// Optional description of the data element
  final String? description;
  
  /// Optional display identifier
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
///
/// Legal entities are organizations or companies that process personal data
/// for a given purpose.
class LegalEntity {
  /// Unique identifier for the legal entity
  final String id;
  
  /// Name of the legal entity
  final String name;
  
  /// Optional description
  final String? description;
  
  /// Optional display identifier
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
///
/// Tools define what technologies or services are used to process data
/// for a given purpose (e.g., analytics tools, advertising platforms).
class Tool {
  /// Unique identifier for the tool
  final String id;
  
  /// Name of the tool
  final String name;
  
  /// Optional description
  final String? description;
  
  /// Optional display identifier
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
///
/// Processing activities define what operations are performed on data
/// (e.g., collection, storage, analysis, sharing).
class ProcessingActivity {
  /// Unique identifier for the processing activity
  final String id;
  
  /// Name of the processing activity
  final String name;
  
  /// Optional description
  final String? description;
  
  /// Optional display identifier
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
///
/// Assets can include logos, images, or other resources displayed in the banner.
class Asset {
  /// Unique identifier for the asset
  final String id;
  
  /// Name of the asset
  final String name;
  
  /// Optional description
  final String? description;
  
  /// Type of asset (e.g., 'logo', 'image')
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
///
/// Contains cookie definitions and selected data elements/processing activities
/// for cookie consent flows.
class CookieConfig {
  /// List of cookies defined in the configuration
  final List<Cookie>? cookies;
  
  /// IDs of selected data elements for cookie consent
  final List<String>? selectedDataElementIds;
  
  /// IDs of selected processing activities for cookie consent
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
///
/// Defines a cookie's properties including name, category, domain, and expiry.
class Cookie {
  /// Optional cookie identifier
  final String? id;
  
  /// Cookie name
  final String? name;
  
  /// Cookie category (e.g., 'essential', 'analytics', 'advertising')
  final String? category;
  
  /// Domain where the cookie is set
  final String? domain;
  
  /// Cookie expiry period
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
///
/// Contains UI customization settings for the consent banner including colors,
/// fonts, text content, and display options.
class BannerSettings {
  /// Font type/family for the banner
  final String? fontType;
  
  /// Font size for the banner
  final String? fontSize;
  
  /// Primary color for buttons and accents (hex format)
  final String? primaryColor;
  
  /// Secondary color (hex format)
  final String? secondaryColor;
  
  /// Text for the main action button
  final String? actionButtonText;
  
  /// Warning text to display
  final String? warningText;
  
  /// Logo URL to display in the banner
  final String? logoUrl;
  
  /// Banner title text
  final String? bannerTitle;
  
  /// Disclaimer text
  final String? disclaimerText;
  
  /// Footer text with links and information
  final String? footerText;
  
  /// Whether to show purposes in the banner
  final bool? showPurposes;

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
    );
  }
}

/// Represents the organization that owns the consent banner.
///
/// Contains organization information including name, legal name, and trade name.
class Organization {
  /// Organization name
  final String name;
  
  /// Legal name of the organization
  final String? legalName;
  
  /// Trade name of the organization
  final String? tradeName;
  
  /// Organization logo URL
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
///
/// Used to track what action the user took when interacting with the consent banner.
enum ConsentAction {
  /// User approved/accepted all purposes
  approved,
  
  /// User declined/rejected all purposes
  declined,
  
  /// User closed the banner without taking action
  noAction,
  
  /// User revoked previously given consent
  revoked,
  
  /// User accepted some purposes but not all (partial consent)
  partialConsent,
}

extension ConsentActionExtension on ConsentAction {
  String get value {
    switch (this) {
      case ConsentAction.approved:
        return 'approved';
      case ConsentAction.declined:
        return 'declined';
      case ConsentAction.noAction:
        return 'no_action';
      case ConsentAction.revoked:
        return 'revoked';
      case ConsentAction.partialConsent:
        return 'partial_consent';
    }
  }
}

