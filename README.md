# truconsent_consent_banner_flutter

Flutter SDK for TruConsent consent banner. This package provides native Flutter widgets for displaying and managing consent banners in Flutter applications.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  truconsent_consent_banner_flutter: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Usage

```dart
import 'package:truconsent_consent_banner_flutter/truconsent_consent_banner_flutter.dart';

TruConsentModal(
  apiKey: 'your-api-key',
  organizationId: 'your-org-id',
  bannerId: 'your-banner-id',
  userId: 'user-id',
  onClose: (action) {
    print('Consent action: $action');
  },
)
```

## API

### TruConsentModal

Main widget for displaying the consent banner modal.

#### Parameters

- `apiKey` (String, required): API key for authentication
- `organizationId` (String, required): Organization ID
- `bannerId` (String, required): Banner/Collection Point ID
- `userId` (String, required): User ID for consent tracking
- `apiBaseUrl` (String, optional): Base URL for API
- `logoUrl` (String, optional): Company logo URL
- `companyName` (String, optional): Company name
- `onClose` (Function, optional): Callback when modal closes

## License

MIT

