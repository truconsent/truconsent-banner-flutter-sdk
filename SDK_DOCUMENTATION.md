# TruConsent Flutter SDK - Complete Documentation

This document lists every component shipped in the TruConsent Flutter SDK, including public APIs, models, services, utilities, widgets, configuration, dependencies, and file structure.

## 1. Overview

The TruConsent Flutter SDK is a comprehensive solution for displaying and managing consent banners in Flutter applications. It provides native Flutter widgets for collecting user consent, supporting GDPR, CCPA, DPDPA, and other privacy regulations.

### Key Features

- **Native Flutter Widgets**: Built specifically for Flutter applications (iOS, Android, Web)
- **Multiple Consent Types**: Supports standard consent, cookie consent, and general consent
- **Flexible Purpose Management**: Users can accept/decline individual purposes or use bulk actions
- **Internationalization**: Built-in support for multiple languages (English, Hindi, Tamil)
- **Customizable UI**: Modern, responsive interface with Material Design
- **Consent Tracking**: Automatic logging of consent actions to the TruConsent API
- **Rights Center**: Comprehensive rights management interface (RightCenter component) with WebView integration
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Auto-showing Wrapper**: TruConsent widget for automatic modal display

## 2. Package Metadata

- Package: truconsent_consent_banner_flutter
- Version: 0.1.0
- Homepage: https://github.com/truconsent/consent-banner-flutter
- Dart SDK: >=3.0.0 <4.0.0
- Flutter SDK: >=3.0.0

### Dependencies

Runtime:
- flutter
- flutter_localizations
- http ^1.1.0
- provider ^6.1.1
- intl ^0.20.2
- uuid ^4.3.0
- url_launcher ^6.2.0
- webview_flutter ^4.4.2

Dev:
- flutter_test
- flutter_lints ^3.0.0
- mockito ^5.4.4
- build_runner ^2.4.7

## 3. Entry Points (Public Exports)

The SDK exports all public APIs through:
- lib/truconsent_consent_banner_flutter.dart
- lib/tru_consent.dart

Both files export the same symbols:
- Widgets
  - TruConsentModal (Main modal component)
  - TruConsent (Auto-showing wrapper for TruConsentModal)
  - BannerUI (Standard consent UI)
  - CookieBannerUI (Cookie consent UI)
  - RightCenter (Rights management component with WebView)
- Models
  - Banner
  - Purpose
  - DataElement
  - LegalEntity
  - Tool
  - ProcessingActivity
  - Asset
  - CookieConfig
  - Cookie
  - BannerSettings
  - Organization
  - ConsentAction
- Services
  - fetchBanner
  - submitConsent
  - defaultApiBaseUrl
- Consent utilities
  - updatePurposeStatus
  - acceptMandatoryPurposes
  - determineConsentAction
  - getAcceptedPurposes
  - getDeclinedPurposes
  - hasOptionalAccepted
  - hasMandatoryPurposes
- I18n helper
  - I18n

## 4. Folder Structure

lib/
- truconsent_consent_banner_flutter.dart
- tru_consent.dart
- src/
  - models/
    - banner.dart
  - services/
    - banner_service.dart
    - consent_manager.dart
  - utils/
    - i18n.dart
    - locales/
      - en.dart
      - ta.dart
      - hi.dart
  - widgets/
    - tru_consent_modal.dart
    - banner_ui.dart
    - cookie_banner_ui.dart
    - modern_banner_header.dart
    - modern_purpose_card.dart
    - modern_banner_footer.dart
    - modern_banner_actions.dart
    - collapsible_data_section.dart

## 5. Core Widget: TruConsentModal

File: lib/src/widgets/tru_consent_modal.dart

Purpose:
- Main modal dialog that loads banner configuration and renders the consent UI.
- Handles API calls, error states, and consent submission.

Constructor Parameters:
- apiKey (String, required): API key for authentication.
- organizationId (String, required): Organization ID.
- bannerId (String, required): Banner/Collection Point ID.
- userId (String, required): Unique user identifier for consent tracking.
- apiBaseUrl (String?, optional): Override API base URL. Defaults to defaultApiBaseUrl.
- logoUrl (String?, optional): Override logo URL shown in the header.
- companyName (String, optional): Fallback company name. Default: Mars Company.
- onClose (Function(ConsentAction)?, optional): Callback when the modal closes.

Runtime Behavior:
- Fetches banner data using fetchBanner.
- Displays error states for missing or invalid credentials and banner IDs.
- Renders BannerUI or CookieBannerUI based on banner.consentType.
- Submits consent using submitConsent with a requestId (UUID v4).
- Tracks whether user took action and logs noAction if closed without action.
- Responsive dialog sizing with mobile and desktop breakpoints.

## 5. Banner UI Widgets

### 5.1 BannerUI

File: lib/src/widgets/banner_ui.dart

Purpose:
- High-level UI composition for the banner experience.

Key Props:
- banner (Banner)
- companyName (String)
- logoUrl (String?)
- onChangePurpose (Function(String purposeId, String status))
- onRejectAll (VoidCallback)
- onConsentAll (VoidCallback)
- onAcceptSelected (VoidCallback)
- primaryColor (String?)
- secondaryColor (String?)

Key Elements:
- ModernBannerHeader
- List of ModernPurposeCard widgets
- ModernBannerFooter
- ModernBannerActions

### 5.2 CookieBannerUI

File: lib/src/widgets/cookie_banner_ui.dart

Purpose:
- Alternative UI for cookie consent configuration.

Key Props:
- banner (Banner)
- companyName (String)
- logoUrl (String?)
- onRejectAll (VoidCallback)
- onConsentAll (VoidCallback)
- primaryColor (String?)
- secondaryColor (String?)

Features:
- Accordion sections for purposes, data elements, and processing activities.
- Action buttons for Accept All, Reject All, and Manage Preferences.

### 5.3 ModernBannerHeader

File: lib/src/widgets/modern_banner_header.dart

Purpose:
- Renders the top header with title, logo, disclaimer, and language selector.

Features:
- Template replacement for [Organization Name] and {{companyName}}.
- Language selector with English, Tamil, Hindi.
- Responsive typography and spacing.

### 5.4 ModernPurposeCard

File: lib/src/widgets/modern_purpose_card.dart

Purpose:
- Renders a single purpose card with description and consent toggle.

Features:
- Mandatory badge display.
- Expiry label display.
- Toggle switch for accept/decline.
- Collapsible data sections for data elements, tools, legal entities, and processing activities.

### 5.5 ModernBannerActions

File: lib/src/widgets/modern_banner_actions.dart

Purpose:
- Renders primary and secondary action buttons for consent.

Behavior:
- Dynamically labels the third button as Accept Selected or Accept Only Necessary.
- Handles disabled state when no optional purposes selected.
- Responsive layout for small screens.

### 5.6 ModernBannerFooter

File: lib/src/widgets/modern_banner_footer.dart

Purpose:
- Renders footer legal text with link parsing.

Features:
- Parses markdown-style links in footer text and opens them with url_launcher.
- Replaces [Organization Name] placeholder with org name.

### 5.7 CollapsibleDataSection

File: lib/src/widgets/collapsible_data_section.dart

Purpose:
- Generic collapsible section used in purpose cards.

Props:
- title (String)
- items (List<dynamic>)
- isOpen (bool)
- onToggle (VoidCallback)

## 7. Models

All models are defined in lib/src/models/banner.dart.

### Banner
- bannerId
- collectionPoint
- version
- title
- expiryType
- asset (Asset?)
- purposes (List<Purpose>)
- dataElements (List<DataElement>?)
- legalEntities (List<LegalEntity>?)
- tools (List<Tool>?)
- processingActivities (List<ProcessingActivity>?)
- consentType (String?)
- cookieConfig (CookieConfig?)
- bannerSettings (BannerSettings?)
- organization (Organization?)
- organizationName (String?)

### Purpose
- id
- name
- description
- isMandatory
- consented (accepted, declined, pending)
- expiryPeriod
- expiryLabel (String?)
- dataElements (List<DataElement>?)
- processingActivities (List<ProcessingActivity>?)
- legalEntities (List<LegalEntity>?)
- tools (List<Tool>?)

### DataElement
- id
- name
- description (String?)
- displayId (String?)

### LegalEntity
- id
- name
- description (String?)
- displayId (String?)

### Tool
- id
- name
- description (String?)
- displayId (String?)

### ProcessingActivity
- id
- name
- description (String?)
- displayId (String?)

### Asset
- id
- name
- description (String?)
- assetType (String?)

### CookieConfig
- cookies (List<Cookie>?)
- selectedDataElementIds (List<String>?)
- selectedProcessingActivityIds (List<String>?)

### Cookie
- id (String?)
- name (String?)
- category (String?)
- domain (String?)
- expiry (String?)

### BannerSettings
- fontType (String?)
- fontSize (String?)
- primaryColor (String?)
- secondaryColor (String?)
- actionButtonText (String?)
- warningText (String?)
- logoUrl (String?)
- bannerTitle (String?)
- disclaimerText (String?)
- footerText (String?)
- showPurposes (bool?)

### Organization
- name
- legalName (String?)
- tradeName (String?)
- logoUrl (String?)

### ConsentAction
- approved
- declined
- noAction
- revoked
- partialConsent

ConsentActionExtension.value returns:
- approved -> approved
- declined -> declined
- noAction -> no_action
- revoked -> revoked
- partialConsent -> partial_consent

## 8. Services

### BannerService (banner_service.dart)

Constants:
- defaultApiBaseUrl
  - https://rdwcymn5poo6zbzg5fa5xzjsqy0zzcpm.lambda-url.ap-south-1.on.aws/banners

Functions:
- fetchBanner({bannerId, apiKey, organizationId, apiBaseUrl})
  - HTTP GET to apiBaseUrl/bannerId
  - Validates required parameters
  - Handles 401, 403, 404 errors
  - Detects and parses HTML error pages
  - Returns Banner

- submitConsent({collectionPointId, userId, purposes, action, apiKey, organizationId, requestId, apiBaseUrl})
  - HTTP POST to apiBaseUrl/collectionPointId/consent
  - Sends userId, purposes, action, requestId
  - Returns Map<String, dynamic>

## 9. Consent Manager

File: lib/src/services/consent_manager.dart

Functions:
- updatePurposeStatus(purposes, purposeId, newStatus)
- acceptMandatoryPurposes(purposes)
- determineConsentAction(purposes, [previousPurposes])
- getAcceptedPurposes(purposes)
- getDeclinedPurposes(purposes)
- hasOptionalAccepted(purposes)
- hasMandatoryPurposes(purposes)

## 10. Internationalization (i18n)

### I18n Helper
File: lib/src/utils/i18n.dart

- setLocale(Locale locale)
- translate(String key, {Map<String, String>? params})
- t(String key, {Map<String, String>? params})

Supported locales:
- en (English)
- ta (Tamil)
- hi (Hindi)

Translation files:
- lib/src/utils/locales/en.dart
- lib/src/utils/locales/ta.dart
- lib/src/utils/locales/hi.dart

Keys provided:
- consent_by
- decline_rights
- expiry_type
- accept
- reject_all
- accept_all
- accept_only_necessary
- accept_selected
- i_consent
- mandatory
- data_elements
- legal_entities
- tools
- processing_activities
- data_processors

## 11. Example and Testing

Example app:
- example/

Testing:
- test/
- TESTING_ISSUES.md contains known issues and guidance.

## 12. Error Handling

Handled error scenarios in fetchBanner:
- Missing bannerId / apiKey / organizationId
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- Non-JSON HTML error responses

Handled error scenarios in submitConsent:
- Non-200/201 response
- Missing required parameters

UI error presentation in TruConsentModal:
- Auth errors
- Banner not found
- Access denied
- Generic server errors

## 13. Customization and Theming

- bannerSettings.primaryColor, bannerSettings.secondaryColor
- bannerSettings.logoUrl
- bannerSettings.bannerTitle
- bannerSettings.disclaimerText
- bannerSettings.footerText
- bannerSettings.actionButtonText
- companyName and logoUrl overrides in TruConsentModal

## 14. Consent Flow Summary

1. TruConsentModal loads banner data via fetchBanner.
2. BannerUI or CookieBannerUI renders based on banner.consentType.
3. User toggles purposes and presses an action button.
4. Consent action is submitted with submitConsent.
5. onClose is called with ConsentAction.

## 15. Known Limits and Defaults

- defaultApiBaseUrl is preconfigured for the TruConsent API.
- Consent status values are expected as strings: accepted, declined, pending.
- Language selector is visual; actual text is handled through local translations and template replacements.
- Dialog sizing uses a responsive breakpoint around 768px.

## 16. Related Documents

- README.md
- INTEGRATION_GUIDE.md
- TESTING_ISSUES.md
