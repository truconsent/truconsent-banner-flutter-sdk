# TruConsent Flutter SDK - Complete Integration Guide

This comprehensive guide will help you integrate the TruConsent Flutter SDK into your Flutter application. We'll use real-world examples from the Mars Money Flutter app to demonstrate best practices.

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Basic Usage - Consent Modal](#basic-usage---consent-modal)
6. [Rights Center Integration](#rights-center-integration)
7. [Complete Examples](#complete-examples)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

## Introduction

The TruConsent Flutter SDK provides native Flutter widgets for displaying consent banners and managing user privacy rights. It helps you comply with GDPR and other privacy regulations by:

- Displaying consent banners with customizable purposes
- Collecting and tracking user consent
- Providing a Rights Center for users to manage their data
- Supporting multiple languages (English, Hindi, Tamil)

**Published Package**: [truconsent_consent_notice_flutter on pub.dev](https://pub.dev/packages/truconsent_consent_notice_flutter)

**GitHub Repository**: [truconsent-banner-flutter-sdk](https://github.com/truconsent/truconsent-banner-flutter-sdk)

## Prerequisites

Before you begin, ensure you have:

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- A TruConsent account with:
  - API Key
  - Organization ID
  - Banner/Collection Point IDs configured
- Basic understanding of Flutter widgets and state management

## Installation

### Step 1: Add the Dependency

Add the TruConsent SDK to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Other dependencies...
  
  # TruConsent SDK
  truconsent_consent_notice_flutter: ^0.1.2
```

### Step 2: Install Dependencies

Run the following command to install the package:

```bash
flutter pub get
```

### Step 3: Verify Installation

You can verify the installation by checking if the package appears in your `pubspec.lock` file or by importing it in a Dart file:

```dart
import 'package:truconsent_consent_notice_flutter/truconsent_consent_banner_flutter.dart';
```

If the import works without errors, the installation is successful.

## Configuration

### Step 1: Create a Configuration File

Create a configuration file to store your TruConsent credentials. This keeps your API keys organized and makes them easy to update.

**File**: `lib/config/truconsent_config.dart`

```dart
/// TruConsent Configuration
/// Update these values with your actual TruConsent credentials
class TruConsentConfig {
  // TruConsent API credentials
  static const String apiKey = 'your-api-key-here';
  static const String organizationId = 'your-organization-id';
  
  // Optional: Custom API base URL if using self-hosted instance
  static const String apiBaseUrl = 'https://your-api-base-url.com/banners';
  
  // Company information
  static const String companyName = 'Your Company Name';
  static const String? logoUrl = null; // Optional: Add your company logo URL
  
  /// Banner IDs - Map your services to collection point IDs
  /// Banking Services
  static const Map<String, String> bankingBannerIds = {
    'savings': 'CP003',
    'salary': 'CP003',
    'credit': 'CP007',
  };
  
  /// Investment Services
  static const Map<String, String> investmentBannerIds = {
    'gold': 'CP008',
    'mutual-funds': 'CP009',
    'demat': 'CP012',
    'fixed-deposit': 'CP010',
  };
  
  /// Get banner ID for a service
  static String getBannerId(String serviceId, String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'banking':
        return bankingBannerIds[serviceId] ?? 'CP003';
      case 'investment':
        return investmentBannerIds[serviceId] ?? 'CP008';
      default:
        return 'CP003';
    }
  }
}
```

**Important**: Replace the placeholder values with your actual credentials from your TruConsent dashboard.

### Step 2: Add Required Dependencies (if not already present)

The SDK requires some common Flutter packages. Add these to your `pubspec.yaml` if you don't already have them:

```yaml
dependencies:
  uuid: ^4.0.0  # For generating guest IDs
  shared_preferences: ^2.2.0  # For storing guest IDs
```

## Basic Usage - Consent Modal

The `TruConsentModal` widget displays a consent banner that users interact with before submitting forms or accessing features.

### Step 1: Create a Guest ID Utility

For unauthenticated users, you'll need to generate and persist a guest ID. Create a utility class:

**File**: `lib/utils/guest_id_utils.dart`

```dart
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestIdUtils {
  static const String _guestIdKey = 'app_guest_id';
  
  /// Get or create a persistent guest ID
  static Future<String> getGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    String? guestId = prefs.getString(_guestIdKey);
    
    if (guestId == null) {
      guestId = const Uuid().v4();
      await prefs.setString(_guestIdKey, guestId);
    }
    
    return guestId;
  }
  
  /// Clear the guest ID (useful for testing or reset)
  static Future<void> clearGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestIdKey);
  }
}
```

### Step 2: Integrate Consent Modal in Your Form

Here's how to integrate the consent modal in a form screen, based on the Mars Money app pattern:

```dart
import 'package:flutter/material.dart';
import 'package:truconsent_consent_notice_flutter/truconsent_consent_banner_flutter.dart';
import '../config/truconsent_config.dart';
import '../utils/guest_id_utils.dart';

class MyFormScreen extends StatefulWidget {
  @override
  _MyFormScreenState createState() => _MyFormScreenState();
}

class _MyFormScreenState extends State<MyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showConsentBanner = false;
  String? _userId;
  String? _guestId;
  bool _isLoadingConsent = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    // If you have user authentication, use the authenticated user ID
    // Otherwise, use a guest ID
    final user = await getAuthenticatedUser(); // Your auth method
    
    if (user != null) {
      setState(() {
        _userId = user.id;
      });
    } else {
      final guestId = await GuestIdUtils.getGuestId();
      setState(() {
        _guestId = guestId;
      });
    }
  }

  void _handleFormSubmit() {
    if (_formKey.currentState!.validate()) {
      // Show consent banner before submitting
      setState(() {
        _showConsentBanner = true;
        _isLoadingConsent = true;
      });
      
      // Ensure guest ID is loaded if needed
      if (_userId == null && _guestId == null) {
        GuestIdUtils.getGuestId().then((id) {
          setState(() {
            _guestId = id;
            _isLoadingConsent = false;
          });
        });
      } else {
        setState(() {
          _isLoadingConsent = false;
        });
      }
    }
  }

  void _submitApplication() {
    // Your form submission logic here
    print('Submitting application...');
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId ?? _guestId;
    
    return Scaffold(
      appBar: AppBar(title: Text('My Form')),
      body: Stack(
        children: [
          // Your form content
          Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Your form fields here
                ElevatedButton(
                  onPressed: _handleFormSubmit,
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
          
          // Consent Modal Overlay
          if (_showConsentBanner && userId != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 500,
                      maxHeight: 600,
                    ),
                    margin: EdgeInsets.all(16),
                    child: _isLoadingConsent
                        ? Card(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          )
                        : TruConsentModal(
                            apiKey: TruConsentConfig.apiKey,
                            organizationId: TruConsentConfig.organizationId,
                            bannerId: 'CP003', // Your banner ID
                            userId: userId!,
                            companyName: TruConsentConfig.companyName,
                            logoUrl: TruConsentConfig.logoUrl,
                            apiBaseUrl: TruConsentConfig.apiBaseUrl,
                            onClose: (action) {
                              setState(() {
                                _showConsentBanner = false;
                              });
                              
                              // Handle consent action
                              if (action == ConsentAction.approved) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Consent approved! Submitting...'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _submitApplication();
                              } else if (action == ConsentAction.declined) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Consent declined. Cannot proceed.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else if (action == ConsentAction.partialConsent) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Partial consent accepted. Submitting...'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                                _submitApplication();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Consent banner closed.'),
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

### Understanding Consent Actions

The `onClose` callback receives a `ConsentAction` enum value:

- **`ConsentAction.approved`**: User accepted all purposes - proceed with submission
- **`ConsentAction.declined`**: User rejected all purposes - block submission
- **`ConsentAction.partialConsent`**: User accepted some purposes - proceed with limitations
- **`ConsentAction.revoked`**: User revoked previously given consent - block submission
- **`ConsentAction.noAction`**: User closed the banner without action - handle appropriately

## Rights Center Integration

The `NativeRightCenter` widget provides a complete Rights Center interface where users can:

- View and manage consent records
- Exercise data rights (deletion, download)
- View transparency information
- Contact the Data Protection Officer (DPO)
- Manage nominees
- Submit and view grievance tickets

### Step 1: Create a Rights Center Screen

**File**: `lib/screens/rights_center_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:truconsent_consent_notice_flutter/truconsent_consent_banner_flutter.dart';
import '../config/truconsent_config.dart';
import '../utils/guest_id_utils.dart';
// import '../providers/auth_provider.dart'; // If using auth

class RightsCenterScreen extends StatefulWidget {
  const RightsCenterScreen({Key? key}) : super(key: key);

  @override
  State<RightsCenterScreen> createState() => _RightsCenterScreenState();
}

class _RightsCenterScreenState extends State<RightsCenterScreen> {
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    // Check if user is authenticated
    // final user = ref.read(authProvider); // If using Riverpod/Provider
    
    // For this example, we'll use guest ID
    // In production, use authenticated user ID when available
    final user = await getAuthenticatedUser(); // Your auth method
    
    if (user != null) {
      setState(() {
        _userId = user.id;
        _isLoading = false;
      });
    } else {
      // Use guest ID for unauthenticated users
      final guestId = await GuestIdUtils.getGuestId();
      setState(() {
        _userId = guestId;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rights Center'),
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _userId != null
              ? NativeRightCenter(
                  userId: _userId!,
                  apiKey: TruConsentConfig.apiKey,
                  organizationId: TruConsentConfig.organizationId,
                  apiBaseUrl: TruConsentConfig.apiBaseUrl,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to load Rights Center',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please try again later',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                          });
                          _loadUserId();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
```

### Step 2: Add Navigation to Rights Center

Add a button or menu item to navigate to the Rights Center:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RightsCenterScreen(),
  ),
);
```

## Complete Examples

### Example 1: Banking Service Form with Consent

This example shows a complete form integration pattern from the Mars Money app:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truconsent_consent_notice_flutter/truconsent_consent_banner_flutter.dart';
import '../config/truconsent_config.dart';
import '../utils/guest_id_utils.dart';
import '../providers/auth_provider.dart'; // Your auth provider

class BankingServiceScreen extends ConsumerStatefulWidget {
  final String serviceId;
  
  const BankingServiceScreen({required this.serviceId});

  @override
  ConsumerState<BankingServiceScreen> createState() => _BankingServiceScreenState();
}

class _BankingServiceScreenState extends ConsumerState<BankingServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showConsentBanner = false;
  String? _guestId;
  bool _isLoadingConsent = false;

  @override
  void initState() {
    super.initState();
    _initGuestId();
  }

  Future<void> _initGuestId() async {
    _guestId = await GuestIdUtils.getGuestId();
  }

  String _getBannerId() {
    return TruConsentConfig.getBannerId(widget.serviceId, 'banking');
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _showConsentBanner = true;
      });
    }
  }

  void _submitApplication() {
    // Your submission logic
    print('Application submitted');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final userId = user?.id ?? _guestId;

    return Scaffold(
      appBar: AppBar(title: Text('Banking Service')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Your form fields
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: Text('Submit Application'),
                ),
              ],
            ),
          ),
          if (_showConsentBanner && userId != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
                    margin: EdgeInsets.all(16),
                    child: _isLoadingConsent || _guestId == null
                        ? Card(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        : TruConsentModal(
                            apiKey: TruConsentConfig.apiKey,
                            organizationId: TruConsentConfig.organizationId,
                            bannerId: _getBannerId(),
                            userId: userId!,
                            companyName: TruConsentConfig.companyName,
                            logoUrl: TruConsentConfig.logoUrl,
                            apiBaseUrl: TruConsentConfig.apiBaseUrl,
                            onClose: (action) {
                              setState(() => _showConsentBanner = false);
                              
                              if (action == ConsentAction.approved) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Consent approved! Submitting...'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _submitApplication();
                              } else if (action == ConsentAction.declined) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Consent declined. Cannot proceed.'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

## Troubleshooting

### Issue: Banner Not Loading

**Symptoms**: The consent modal shows a loading spinner indefinitely or displays an error.

**Solutions**:
1. **Check API Credentials**: Verify your `apiKey` and `organizationId` in `TruConsentConfig`
2. **Verify Banner ID**: Ensure the banner ID exists in your TruConsent dashboard
3. **Check Network**: Ensure the device has internet connectivity
4. **Check API Base URL**: If using a custom API base URL, verify it's correct
5. **Check Console Logs**: Look for error messages in the debug console

**Example Error Handling**:
```dart
TruConsentModal(
  // ... other parameters
  onClose: (action) {
    if (action == ConsentAction.noAction) {
      // Handle error cases
      print('Banner closed without action - check logs for errors');
    }
  },
)
```

### Issue: User ID Not Available

**Symptoms**: Rights Center or consent modal doesn't load.

**Solutions**:
1. **Ensure Guest ID is Generated**: Call `GuestIdUtils.getGuestId()` before showing the modal
2. **Check User Authentication**: If using authenticated users, verify the user ID is available
3. **Add Loading State**: Show a loading indicator while fetching user/guest ID

### Issue: Consent Not Submitting

**Symptoms**: User interacts with banner but consent isn't recorded.

**Solutions**:
1. **Check API Endpoint**: Verify the API base URL is accessible
2. **Check Network**: Ensure device has internet connectivity
3. **Verify User ID**: Ensure a valid user ID is being passed
4. **Check Console Logs**: Look for API error responses

### Issue: Modal Not Displaying

**Symptoms**: `_showConsentBanner` is true but modal doesn't appear.

**Solutions**:
1. **Check User ID**: Ensure `userId` is not null
2. **Check Widget Tree**: Ensure the modal is in the widget tree
3. **Check Constraints**: Verify the container constraints allow the modal to display
4. **Check Z-Index**: Ensure no other widgets are covering the modal

## Best Practices

### 1. User ID Management

- **Always use authenticated user ID when available**: This ensures consent is properly tracked per user
- **Generate guest ID early**: Call `GuestIdUtils.getGuestId()` in `initState()` to avoid delays
- **Persist guest ID**: Use `SharedPreferences` to maintain the same guest ID across app sessions

### 2. Consent Modal Timing

- **Show before form submission**: Display the consent modal when the user clicks submit, not before
- **Handle loading states**: Show a loading indicator while the guest ID is being generated
- **Provide user feedback**: Use SnackBars or dialogs to inform users about consent actions

### 3. Error Handling

- **Always check for null user ID**: Don't show the modal if user ID is null
- **Handle network errors gracefully**: Show user-friendly error messages
- **Log errors for debugging**: Use `debugPrint` or logging libraries to track issues

### 4. Configuration Management

- **Use a config class**: Centralize all TruConsent configuration in one file
- **Don't hardcode credentials**: Consider using environment variables or secure storage for production
- **Map banner IDs**: Create a mapping system for different services to banner IDs

### 5. State Management

- **Use proper state management**: If using Riverpod, Provider, or Bloc, integrate TruConsent widgets properly
- **Avoid unnecessary rebuilds**: Use `const` constructors where possible
- **Dispose resources**: Clean up controllers and listeners in `dispose()`

### 6. User Experience

- **Show consent at the right time**: Don't show consent banners too early or too late in the user flow
- **Provide clear feedback**: Inform users about what happens after they give consent
- **Handle all consent actions**: Don't ignore `partialConsent` or `noAction` cases

## Additional Resources

- **SDK Documentation**: [pub.dev package page](https://pub.dev/packages/truconsent_consent_notice_flutter)
- **GitHub Repository**: [truconsent-banner-flutter-sdk](https://github.com/truconsent/truconsent-banner-flutter-sdk)
- **Example App**: [mars-money-app-flutter](https://github.com/truconsent/mars-money-app-flutter)

## Support

If you encounter issues not covered in this guide:

1. Check the [GitHub Issues](https://github.com/truconsent/truconsent-banner-flutter-sdk/issues)
2. Review the SDK source code for implementation details
3. Contact TruConsent support with:
   - SDK version
   - Flutter version
   - Error messages/logs
   - Steps to reproduce

---

**Last Updated**: Based on SDK version 0.1.2
