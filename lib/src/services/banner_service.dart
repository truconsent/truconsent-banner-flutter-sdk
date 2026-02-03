import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/banner.dart';

String _bodyPreview(String body, {int max = 240}) {
  if (body.length <= max) return body;
  return body.substring(0, max) + '...';
}

/// Default base URL for the TruConsent API
const String defaultApiBaseUrl =
    'https://rdwcymn5poo6zbzg5fa5xzjsqy0zzcpm.lambda-url.ap-south-1.on.aws/banners';

/// Fetches banner configuration from the TruConsent API.
///
/// Retrieves the banner configuration including purposes, data elements,
/// and processing activities for the specified banner ID.
///
/// Throws an [Exception] if:
/// - [bannerId], [apiKey], or [organizationId] is empty
/// - API returns an error status (401, 403, 404, 500)
///
/// Example:
/// ```dart
/// final banner = await fetchBanner(
///   bannerId: 'CP001',
///   apiKey: 'your-api-key',
///   organizationId: 'your-org-id',
/// );
/// ```
Future<Banner> fetchBanner({
  required String bannerId,
  required String apiKey,
  required String organizationId,
  String apiBaseUrl = defaultApiBaseUrl,
}) async {
  if (bannerId.isEmpty) {
    throw Exception('Missing bannerId');
  }
  if (apiKey.isEmpty) {
    throw Exception('Missing apiKey - API key is required for authentication');
  }
  if (organizationId.isEmpty) {
    throw Exception(
        'Missing organizationId - Organization ID is required for authentication');
  }

  final url = Uri.parse('$apiBaseUrl/$bannerId');
  debugPrint('Fetching banner from: $url');
  debugPrint('Headers: X-API-Key=${apiKey.substring(0, 10)}..., X-Org-Id=$organizationId');
  
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'X-Org-Id': organizationId,
    },
  );
  
  debugPrint('Banner API response status: ${response.statusCode}');
  debugPrint('Response headers: ${response.headers}');

  if (response.statusCode == 401) {
    throw Exception('Authentication required - Invalid or missing API key');
  }
  if (response.statusCode == 403) {
    throw Exception(
        'Access forbidden - API key does not have permission to access this banner');
  }
  if (response.statusCode == 404) {
    throw Exception(
        'Banner not found - Banner ID "$bannerId" does not exist or is not accessible');
  }
  // Check content type first to handle HTML/error responses
  final contentType = response.headers['content-type'] ?? '';
  final isJson = contentType.contains('application/json');
  final bodyTrimmed = response.body.trimLeft();
  final isHtml = bodyTrimmed.startsWith('<!DOCTYPE') ||
      bodyTrimmed.startsWith('<!doctype') ||
      bodyTrimmed.startsWith('<html') ||
      contentType.contains('text/html');

  if (response.statusCode != 200) {
    String errorMessage = 'Failed to load banner (${response.statusCode})';
    try {
      if (isJson) {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
      } else if (isHtml) {
        // Extract error from HTML
        final match = RegExp(r'<p>(.*?)</p>', caseSensitive: false)
            .firstMatch(response.body);
        if (match != null && match.group(1) != null) {
          errorMessage = match.group(1)!.trim();
        } else {
          final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false)
              .firstMatch(response.body);
          if (titleMatch != null && titleMatch.group(1) != null) {
            errorMessage = titleMatch.group(1)!.trim();
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing error response: $e');
    }
    debugPrint(
        'Banner fetch failed | status=${response.statusCode} | content-type=$contentType | preview=${_bodyPreview(response.body)}');
    throw Exception(errorMessage);
  }

  // Even with 200 status, check if response is actually JSON
  if (isHtml) {
    String errorMessage =
        'Server returned an error page instead of banner data (status ${response.statusCode}).';
    try {
      final match = RegExp(r'<p>(.*?)</p>', caseSensitive: false)
          .firstMatch(response.body);
      if (match != null && match.group(1) != null) {
        errorMessage = match.group(1)!.trim();
      }
    } catch (e) {
      debugPrint('Error extracting error from HTML: $e');
    }
    debugPrint(
        'Banner fetch returned HTML | status=${response.statusCode} | content-type=$contentType | preview=${_bodyPreview(response.body)}');
    throw Exception(errorMessage);
  }

  // Parse JSON response
  try {
    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return Banner.fromJson(jsonData);
  } catch (e) {
    debugPrint('Error parsing JSON response: $e');
    debugPrint('Response preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
    throw Exception('Failed to parse banner data. The server may have returned an error. Please check your API credentials and banner ID.');
  }
}

/// Submits user consent choices to the TruConsent API.
///
/// Sends the user's consent decisions (accepted/declined purposes) to the backend
/// for storage and tracking.
///
/// Returns a [Map] containing the API response data.
///
/// Throws an [Exception] if:
/// - Required parameters are empty
/// - API returns an error status
///
/// Example:
/// ```dart
/// final response = await submitConsent(
///   collectionPointId: 'CP001',
///   userId: 'user-123',
///   purposes: acceptedPurposes,
///   action: ConsentAction.approved,
///   apiKey: 'your-api-key',
///   organizationId: 'your-org-id',
/// );
/// ```
Future<Map<String, dynamic>> submitConsent({
  required String collectionPointId,
  required String userId,
  required List<Purpose> purposes,
  required ConsentAction action,
  required String apiKey,
  required String organizationId,
  String? requestId,
  String apiBaseUrl = defaultApiBaseUrl,
}) async {
  if (collectionPointId.isEmpty) {
    throw Exception('Missing collectionPointId');
  }
  if (apiKey.isEmpty) {
    throw Exception('Missing apiKey');
  }
  if (organizationId.isEmpty) {
    throw Exception('Missing organizationId');
  }

  final url = Uri.parse('$apiBaseUrl/$collectionPointId/consent');
  debugPrint('📤 Submitting consent to: $url');
  debugPrint('📤 Action: ${action.value}');
  debugPrint('📤 User ID: $userId');
  debugPrint('📤 Purposes: ${purposes.map((p) => p.id).toList()}');
  
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'X-Org-Id': organizationId,
    },
    body: json.encode({
      'userId': userId,
      'purposes': purposes.map((p) => p.toJson()).toList(),
      'action': action.value,
      'requestId': requestId,
    }),
  );

  debugPrint('📥 Consent API response status: ${response.statusCode}');
  debugPrint('📥 Consent API response body: ${response.body}');

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to submit consent');
  }

  return json.decode(response.body) as Map<String, dynamic>;
}

