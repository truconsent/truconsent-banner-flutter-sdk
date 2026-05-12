import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/banner.dart';

String _bodyPreview(String body, {int max = 240}) {
  if (body.length <= max) return body;
  return '${body.substring(0, max)}...';
}

/// Default base URL for the TruConsent API
const String defaultApiBaseUrl = 'https://trukit-dev.truconsent.io';

/// Fetches banner configuration from the TruConsent API.
///
/// URL: GET {apiUrl}/api/v1/internal/consent/{assetId}/{bannerId}?userId={userId}
/// or:  GET {apiUrl}/api/v1/internal/consent/{bannerId}?userId={userId}
Future<Banner> fetchBanner({
  required String bannerId,
  required String apiKey,
  required String organizationId,
  String? userId,
  String? assetId,
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

  final baseWithPath = assetId != null && assetId.isNotEmpty
      ? '$apiBaseUrl/api/v1/internal/consent/$assetId/$bannerId'
      : '$apiBaseUrl/api/v1/internal/consent/$bannerId';

  final queryParams = <String, String>{};
  if (userId != null && userId.isNotEmpty) {
    queryParams['userId'] = userId;
  }

  final uri = Uri.parse(baseWithPath).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
  debugPrint('Fetching banner from: $uri');

  // Backend OriginEnforcementMiddleware blocks /api/v1/internal/consent* unless
  // the request looks like a browser (Sec-Fetch-Site or Mozilla User-Agent).
  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'X-Org-Id': organizationId,
      if (userId != null && userId.isNotEmpty) 'X-User-Id': userId,
      'Sec-Fetch-Site': 'cross-site',
      'User-Agent': 'Mozilla/5.0 TruConsent-Flutter-SDK/1.0',
      // Do NOT send Origin — backend defaults to COLLECTOR_BASE_URL which is always authorized.
    },
  );

  debugPrint('Banner API response status: ${response.statusCode}');

  if (response.statusCode == 401) {
    throw Exception('Unauthorized - Invalid or missing API key');
  }
  if (response.statusCode == 403) {
    throw Exception('Forbidden - This domain is not authorized');
  }
  if (response.statusCode == 429) {
    throw Exception('Rate limit exceeded');
  }
  if (response.statusCode == 404) {
    throw Exception(
        'Banner not found - Banner ID "$bannerId" does not exist or is not accessible');
  }

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
        final match = RegExp(r'<p>(.*?)</p>', caseSensitive: false)
            .firstMatch(response.body);
        if (match?.group(1) != null) {
          errorMessage = match!.group(1)!.trim();
        }
      }
    } catch (e) {
      debugPrint('Error parsing error response: $e');
    }
    debugPrint(
        'Banner fetch failed | status=${response.statusCode} | preview=${_bodyPreview(response.body)}');
    throw Exception(errorMessage);
  }

  if (isHtml) {
    String errorMessage =
        'Server returned an error page instead of banner data (status ${response.statusCode}).';
    try {
      final match = RegExp(r'<p>(.*?)</p>', caseSensitive: false)
          .firstMatch(response.body);
      if (match?.group(1) != null) {
        errorMessage = match!.group(1)!.trim();
      }
    } catch (e) {
      debugPrint('Error extracting error from HTML: $e');
    }
    throw Exception(errorMessage);
  }

  try {
    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    // Support both top-level and nested `data` envelope
    final bannerJson = jsonData.containsKey('data') && jsonData['data'] is Map
        ? (jsonData['data'] as Map<String, dynamic>)
        : jsonData;
    return Banner.fromJson(bannerJson);
  } catch (e) {
    debugPrint('Error parsing JSON response: $e');
    throw Exception(
        'Failed to parse banner data. The server may have returned an error. Please check your API credentials and banner ID.');
  }
}

/// Submits user consent choices to the TruConsent API.
///
/// URL: POST {apiUrl}/api/v1/internal/consent/{collectionPointId}
Future<Map<String, dynamic>> submitConsent({
  required String collectionPointId,
  required String userId,
  required List<Purpose> purposes,
  required ConsentAction action,
  required String apiKey,
  required String organizationId,
  String? requestId,
  String? assetId,
  String? sessionId,
  String? buttonUsed,
  String? reconsentCampaignId,
  String? expiryReconsentRequestId,
  int? bannerFetchedAt,
  int? bannerDisplayedAt,
  int? userInteractionAt,
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

  final url = Uri.parse('$apiBaseUrl/api/v1/internal/consent/$collectionPointId');
  debugPrint('Submitting consent to: $url');
  debugPrint('Action: ${action.value}');

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final body = <String, dynamic>{
    'userId': userId,
    'requestId': requestId,
    'assetId': assetId ?? '',
    'consentLanguage': 'en',
    'collectionPointId': collectionPointId,
    'collectionPointVersion': 'v1.0',
    'consentTimestamp': now,
    'source': 'flutter',
    'purposes': purposes.map((p) => p.toJson()).toList(),
    'action': action.value,
    'metadata': {
      'sessionId': sessionId,
      'button_used': buttonUsed,
      'collection_point_version': 'v1.0',
      'reconsent_campaign_id': reconsentCampaignId,
      'expiry_reconsent_request_id': expiryReconsentRequestId,
      'performance': {
        'banner_fetched_at': bannerFetchedAt,
        'banner_displayed_at': bannerDisplayedAt,
        'user_interaction_at': userInteractionAt ?? now,
        'notice_logged_at': action == ConsentAction.noticeShown ? now : null,
      },
    },
  };

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'X-Org-Id': organizationId,
    },
    body: json.encode(body),
  );

  debugPrint('Consent API response status: ${response.statusCode}');

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to submit consent (${response.statusCode})');
  }

  try {
    return json.decode(response.body) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

/// Sends suppression update (fire-and-forget) after any action where purposes are declined.
///
/// URL: POST {apiUrl}/api/v1/internal/consent/suppression
Future<void> sendSuppressionUpdate({
  required String userId,
  required List<String> declinedPurposeIds,
  required String apiKey,
  required String organizationId,
  String apiBaseUrl = defaultApiBaseUrl,
}) async {
  if (declinedPurposeIds.isEmpty) return;

  final url = Uri.parse('$apiBaseUrl/api/v1/internal/consent/suppression');
  try {
    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
        'X-Org-Id': organizationId,
      },
      body: json.encode({
        'userId': userId,
        'declinedPurposeIds': declinedPurposeIds,
      }),
    );
  } catch (e) {
    // fire-and-forget, swallow errors
    debugPrint('Suppression update failed (ignored): $e');
  }
}

/// Sends a notice_shown event for notice-only banners.
Future<Map<String, dynamic>> sendNoticeShown({
  required String collectionPointId,
  required String userId,
  required List<Purpose> purposes,
  required String apiKey,
  required String organizationId,
  String? requestId,
  String? assetId,
  String? sessionId,
  int? bannerFetchedAt,
  int? bannerDisplayedAt,
  String? reconsentCampaignId,
  String apiBaseUrl = defaultApiBaseUrl,
}) async {
  final noticePurposes = purposes.map((p) => p.copyWith(consented: 'shown')).toList();
  return submitConsent(
    collectionPointId: collectionPointId,
    userId: userId,
    purposes: noticePurposes,
    action: ConsentAction.noticeShown,
    apiKey: apiKey,
    organizationId: organizationId,
    requestId: requestId,
    assetId: assetId,
    sessionId: sessionId,
    buttonUsed: 'i_understand',
    bannerFetchedAt: bannerFetchedAt,
    bannerDisplayedAt: bannerDisplayedAt,
    apiBaseUrl: apiBaseUrl,
  );
}
