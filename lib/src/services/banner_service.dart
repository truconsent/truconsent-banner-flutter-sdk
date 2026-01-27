/// BannerService - HTTP client for banner API calls in Flutter
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/banner.dart';

const String defaultApiBaseUrl =
    'https://rdwcymn5poo6zbzg5fa5xzjsqy0zzcpm.lambda-url.ap-south-1.on.aws/banners';

/// Fetch banner configuration from API
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
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
      'X-Org-Id': organizationId,
    },
  );

  if (response.statusCode == 401) {
    throw Exception('Authentication required - Invalid or missing API key');
  }
  if (response.statusCode == 403) {
    throw Exception(
        'Access forbidden - API key does not have permission to access this banner');
  }
  if (response.statusCode != 200) {
    throw Exception('Failed to load banner');
  }

  final jsonData = json.decode(response.body) as Map<String, dynamic>;
  return Banner.fromJson(jsonData);
}

/// Submit consent to the backend
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

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Failed to submit consent');
  }

  return json.decode(response.body) as Map<String, dynamic>;
}

