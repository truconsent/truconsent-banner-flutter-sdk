# TruConsent Flutter SDK Integration Guide

This guide will help you integrate the TruConsent Flutter SDK into your Flutter application.

## Installation

Add the SDK to your `pubspec.yaml`:

```yaml
dependencies:
  truconsent_consent_notice_flutter:
    git:
      url: https://github.com/truconsent/truconsent-banner-flutter-sdk.git
      ref: main
```

Or if using a local path:

```yaml
dependencies:
  truconsent_consent_notice_flutter:
    path: ../truconsent_consent_notice_flutter
```

Then run:

```bash
flutter pub get
```

## Basic Usage

### 1. Import the SDK

```dart
import 'package:truconsent_consent_notice_flutter/truconsent_consent_banner_flutter.dart';
```

### 2. Add TruConsentModal to your app

```dart
TruConsentModal(
  apiKey: 'your-api-key',
  organizationId: 'your-org-id',
  bannerId: 'your-banner-id',
  userId: 'user-id',
  onClose: (action) {
    print('Consent action: ${action.value}');
  },
)
```

## API Reference

### TruConsentModal

Main widget for displaying the consent banner modal.

#### Parameters

- `apiKey` (String, required): API key for authentication
- `organizationId` (String, required): Organization ID
- `bannerId` (String, required): Banner/Collection Point ID
- `userId` (String, required): User ID for consent tracking
- `apiBaseUrl` (String?, optional): Base URL for API. Defaults to production URL
- `logoUrl` (String?, optional): Company logo URL
- `companyName` (String, optional): Company name. Defaults to 'Mars Company'
- `onClose` (Function(ConsentAction)?, optional): Callback when modal closes

### ConsentAction

Enum representing consent actions:

- `ConsentAction.approved` - User accepted all purposes
- `ConsentAction.declined` - User rejected all purposes
- `ConsentAction.partialConsent` - User accepted some purposes
- `ConsentAction.revoked` - User revoked previously accepted consent
- `ConsentAction.noAction` - User closed without taking action

## Example Implementation

```dart
import 'package:flutter/material.dart';
import 'package:truconsent_consent_notice_flutter/truconsent_consent_banner_flutter.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => TruConsentModal(
                  apiKey: 'your-api-key',
                  organizationId: 'your-org-id',
                  bannerId: 'your-banner-id',
                  userId: 'user-id',
                  onClose: (action) {
                    Navigator.of(context).pop();
                    print('Consent: ${action.value}');
                  },
                ),
              );
            },
            child: Text('Show Consent Banner'),
          ),
        ),
      ),
    );
  }
}
```

## Error Handling

The SDK handles various error scenarios:

- **401 Unauthorized**: Invalid or missing API key
- **403 Forbidden**: API key doesn't have permission
- **404 Not Found**: Banner ID doesn't exist
- **500 Server Error**: Server-side error (with HTML error parsing)

Error messages are displayed in the modal with user-friendly text.

## Internationalization

The SDK supports multiple languages:
- English (en)
- Tamil (ta)
- Hindi (hi)

Language can be changed via the language selector in the banner header.

## Testing

Run the example app to test the SDK:

```bash
cd example
flutter run
```

## Support

For issues or questions, please open an issue on the GitHub repository.

