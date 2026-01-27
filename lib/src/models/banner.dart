/// Banner model for TruConsent Flutter SDK
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

class Purpose {
  final String id;
  final String name;
  final String description;
  final bool isMandatory;
  final String consented; // 'accepted', 'declined', 'pending'
  final String expiryPeriod;
  final String? expiryLabel;
  final List<DataElement>? dataElements;
  final List<ProcessingActivity>? processingActivities;
  final List<LegalEntity>? legalEntities;
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

enum ConsentAction {
  approved,
  declined,
  noAction,
  revoked,
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

