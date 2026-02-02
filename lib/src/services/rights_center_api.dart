/// Rights Center API Service
/// Handles all API calls for the Rights Center feature
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ConsentGroup {
  final String collection_point;
  final String title;
  final List<Purpose> purposes;
  final List<DataElement>? data_elements;
  final bool? shown_to_principal;

  ConsentGroup({
    required this.collection_point,
    required this.title,
    required this.purposes,
    this.data_elements,
    this.shown_to_principal,
  });

  factory ConsentGroup.fromJson(Map<String, dynamic> json) {
    return ConsentGroup(
      collection_point: json['collection_point'] ?? '',
      title: json['title'] ?? '',
      purposes: (json['purposes'] as List<dynamic>?)
              ?.map((p) => Purpose.fromJson(p))
              .toList() ??
          [],
      data_elements: (json['data_elements'] as List<dynamic>?)
          ?.map((e) => DataElement.fromJson(e))
          .toList(),
      shown_to_principal: json['shown_to_principal'] as bool?,
    );
  }
}

class Purpose {
  final String id;
  final String name;
  final String description;
  final String expiry_period;
  final bool is_mandatory;
  final String consented; // 'accepted', 'declined', 'pending'

  Purpose({
    required this.id,
    required this.name,
    required this.description,
    required this.expiry_period,
    required this.is_mandatory,
    required this.consented,
  });

  factory Purpose.fromJson(Map<String, dynamic> json) {
    return Purpose(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      expiry_period: json['expiry_period'] ?? '',
      is_mandatory: json['is_mandatory'] ?? false,
      consented: json['consented'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'consented': consented,
    };
  }
}

class DataElement {
  final String name;
  final String description;

  DataElement({
    required this.name,
    required this.description,
  });

  factory DataElement.fromJson(Map<String, dynamic> json) {
    return DataElement(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class DPOInfo {
  final String? full_name;
  final String? email;
  final String? appointment_date;
  final String? qualifications;
  final String? responsibilities;

  DPOInfo({
    this.full_name,
    this.email,
    this.appointment_date,
    this.qualifications,
    this.responsibilities,
  });

  factory DPOInfo.fromJson(Map<String, dynamic> json) {
    return DPOInfo(
      full_name: json['full_name'],
      email: json['email'],
      appointment_date: json['appointment_date'],
      qualifications: json['qualifications'],
      responsibilities: json['responsibilities'],
    );
  }
}

class Nominee {
  final String? id;
  final String nominee_name;
  final String relationship;
  final String nominee_email;
  final String nominee_mobile;
  final String? purpose_of_appointment;
  final String? user_id;

  Nominee({
    this.id,
    required this.nominee_name,
    required this.relationship,
    required this.nominee_email,
    required this.nominee_mobile,
    this.purpose_of_appointment,
    this.user_id,
  });

  factory Nominee.fromJson(Map<String, dynamic> json) {
    return Nominee(
      id: json['id'],
      nominee_name: json['nominee_name'] ?? '',
      relationship: json['relationship'] ?? '',
      nominee_email: json['nominee_email'] ?? '',
      nominee_mobile: json['nominee_mobile'] ?? '',
      purpose_of_appointment: json['purpose_of_appointment'],
      user_id: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nominee_name': nominee_name,
      'relationship': relationship,
      'nominee_email': nominee_email,
      'nominee_mobile': nominee_mobile,
      if (purpose_of_appointment != null)
        'purpose_of_appointment': purpose_of_appointment,
      if (user_id != null) 'user_id': user_id,
    };
  }
}

class GrievanceTicket {
  final String? id;
  final String subject;
  final String category;
  final String description;
  final String? status;
  final String? created_at;
  final String? client_user_id;

  GrievanceTicket({
    this.id,
    required this.subject,
    required this.category,
    required this.description,
    this.status,
    this.created_at,
    this.client_user_id,
  });

  factory GrievanceTicket.fromJson(Map<String, dynamic> json) {
    return GrievanceTicket(
      id: json['id'],
      subject: json['subject'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      status: json['status'],
      created_at: json['created_at'],
      client_user_id: json['client_user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'subject': subject,
      'category': category,
      'description': description,
      if (status != null) 'status': status,
      if (created_at != null) 'created_at': created_at,
      if (client_user_id != null) 'client_user_id': client_user_id,
    };
  }
}

class ConsentPayload {
  final String userId;
  final List<Map<String, dynamic>> purposes;
  final String action; // 'approved', 'revoked', 'declined'
  final List<String>? changedPurposes;

  ConsentPayload({
    required this.userId,
    required this.purposes,
    required this.action,
    this.changedPurposes,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'purposes': purposes,
      'action': action,
      if (changedPurposes != null) 'changedPurposes': changedPurposes,
    };
  }
}

class RightsCenterApi {
  final String baseUrl;
  final String apiKey;
  final String organizationId;

  RightsCenterApi({
    required this.baseUrl,
    required this.apiKey,
    required this.organizationId,
  });

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey.isNotEmpty) {
      headers['X-API-Key'] = apiKey;
    }
    if (organizationId.isNotEmpty) {
      headers['X-Org-Id'] = organizationId;
    }
    return headers;
  }

  Future<dynamic> _request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    // Ensure baseUrl doesn't end with / and endpoint starts with /
    final cleanBaseUrl = baseUrl.replaceAll(RegExp(r'/$'), '');
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = Uri.parse('$cleanBaseUrl$cleanEndpoint');
    final headers = _getHeaders();

    try {
      debugPrint('[RightsCenterApi] Request: $url');
      debugPrint('[RightsCenterApi] Method: $method');
      debugPrint('[RightsCenterApi] Headers: ${headers.keys.join(", ")}');
      
      http.Response response;
      if (method == 'GET') {
        response = await http.get(url, headers: headers);
      } else if (method == 'POST') {
        response = await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (method == 'PUT') {
        response = await http.put(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: headers);
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      debugPrint('[RightsCenterApi] Response status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return null;
        }
        try {
          return jsonDecode(response.body);
        } catch (e) {
          debugPrint('[RightsCenterApi] Failed to parse JSON: $e');
          debugPrint('[RightsCenterApi] Response body: ${response.body.substring(0, 100)}');
          throw Exception('Invalid response format: expected JSON');
        }
      } else {
        // If it's a 404 for root endpoint, this is expected - don't log as error
        if (response.statusCode == 404 && (endpoint == '/' || endpoint == '')) {
          debugPrint('[RightsCenterApi] Root endpoint (/) returned 404 (expected)');
          return <dynamic>[];
        }
        // For other errors, log and throw
        final errorText = response.body.length > 200 
            ? response.body.substring(0, 200) 
            : response.body;
        debugPrint('[RightsCenterApi] Error response: $errorText');
        throw Exception(
          'API Error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('[RightsCenterApi] Request failed: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Consent endpoints
  Future<List<ConsentGroup>> getUserConsents(String userId) async {
    try {
      // API requires first 6 characters of user ID (data principal ID format)
      // Web platform uses: user.id.slice(0,6)
      final dataPrincipalId = userId.length >= 6 ? userId.substring(0, 6) : userId;
      debugPrint('[RightsCenterApi] getUserConsents - Full userId: $userId, Using dataPrincipalId: $dataPrincipalId');
      final response = await _request('/user/${Uri.encodeComponent(dataPrincipalId)}');
      List<ConsentGroup> result = [];
      if (response is List) {
        result = response
            .map((item) => ConsentGroup.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map<String, dynamic>) {
        final list = response['data'] as List<dynamic>? ?? [];
        result = list
            .map((item) => ConsentGroup.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      debugPrint('[RightsCenterApi] getUserConsents - Received ${result.length} user consent records');
      if (result.isNotEmpty) {
        debugPrint('[RightsCenterApi] getUserConsents - Sample record: ${result.first.collection_point} with ${result.first.purposes.length} purposes');
      }
      return result;
    } catch (e) {
      // If 404 or other error, return empty array instead of throwing
      if (e.toString().contains('404')) {
        debugPrint('[RightsCenterApi] getUserConsents returned 404, using empty array');
        return [];
      }
      rethrow;
    }
  }

  Future<List<ConsentGroup>> getAllBanners() async {
    try {
      // Try root endpoint first
      final response = await _request('/');
      List<ConsentGroup> result = [];
      if (response is List) {
        result = response
            .map((item) => ConsentGroup.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map<String, dynamic>) {
        final list = response['data'] as List<dynamic>? ?? [];
        result = list
            .map((item) => ConsentGroup.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      debugPrint('[RightsCenterApi] getAllBanners - Received ${result.length} banners');
      // If root endpoint returned empty array (404 handled), fetch individually
      if (result.isEmpty) {
        debugPrint('[RightsCenterApi] Root endpoint returned empty, fetching all collection points individually...');
        return await _fetchAllCollectionPointsByID();
      }
      if (result.isNotEmpty) {
        debugPrint('[RightsCenterApi] getAllBanners - Sample banner: ${result.first.collection_point} with ${result.first.purposes.length} purposes');
      }
      return result;
    } catch (e) {
      // If any other error, try fetching individually
      debugPrint('[RightsCenterApi] Error fetching from root endpoint, fetching all collection points individually...');
      return await _fetchAllCollectionPointsByID();
    }
  }

  /// Fetch all collection points by their individual IDs
  /// This is a fallback when the root endpoint doesn't work
  Future<List<ConsentGroup>> _fetchAllCollectionPointsByID() async {
    // Known collection point IDs (CP002-CP014 based on system configuration)
    const collectionPointIds = [
      'CP002', // Expense Tracker
      'CP003', // KYC Document Upload Form
      'CP004', // Marketing Consent Banner
      'CP006', // Account Dashboard
      'CP007', // Signup Page
      'CP008', // Credit Card Application Form
      'CP009', // Fixed Deposit Page
      'CP010', // Mutual Funds Investment Section
      'CP011', // Digital Gold Investment Interface
      'CP012', // Loan Application Page
      'CP013', // Demat Account Creation
      'CP014', // Federal Bank Account Opening Form
    ];

    debugPrint('[RightsCenterApi] Fetching ${collectionPointIds.length} collection points individually...');

    final results = await Future.wait(
      collectionPointIds.map((cpId) async {
        try {
          final response = await _request('/${Uri.encodeComponent(cpId)}');
          if (response is Map<String, dynamic>) {
            return ConsentGroup.fromJson(response);
          }
          return null;
        } catch (err) {
          // If a specific collection point doesn't exist, skip it
          debugPrint('[RightsCenterApi] Collection point $cpId not found, skipping');
          return null;
        }
      }),
      eagerError: false,
    );

    final banners = results.whereType<ConsentGroup>().toList();
    debugPrint('[RightsCenterApi] Successfully fetched ${banners.length} collection points');
    return banners;
  }

  Future<void> saveConsent(String collectionId, ConsentPayload payload) async {
    await _request(
      '/${Uri.encodeComponent(collectionId)}/consent',
      method: 'POST',
      body: payload.toJson(),
    );
  }

  // DPO endpoint
  Future<DPOInfo> getDPOInfo() async {
    final response = await _request('/dpo_information');
    if (response is Map<String, dynamic>) {
      return DPOInfo.fromJson(response);
    }
    return DPOInfo();
  }

  // Nominee endpoints
  Future<List<Nominee>> getNominees(String userId) async {
    final response = await _request('/user_nominees/user/${Uri.encodeComponent(userId)}');
      if (response is List) {
        return response
            .map((item) => Nominee.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    if (response is Map<String, dynamic>) {
      final list = response['data'] as List<dynamic>? ?? [];
      return list
          .map((item) => Nominee.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Nominee> createNominee(Nominee nominee) async {
    final response = await _request(
      '/user_nominees',
      method: 'POST',
      body: nominee.toJson(),
    );
    if (response is Map<String, dynamic>) {
      return Nominee.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  Future<Nominee> updateNominee(String id, Nominee nominee) async {
    final response = await _request(
      '/user_nominees/${Uri.encodeComponent(id)}',
      method: 'PUT',
      body: nominee.toJson(),
    );
    if (response is Map<String, dynamic>) {
      return Nominee.fromJson(response);
    }
    throw Exception('Invalid response format');
  }

  Future<void> deleteNominee(String id) async {
    await _request(
      '/user_nominees/${Uri.encodeComponent(id)}',
      method: 'DELETE',
    );
  }

  // Grievance endpoints
  Future<List<GrievanceTicket>> getGrievanceTickets(String userId) async {
    final response = await _request('/grievance_tickets/user/${Uri.encodeComponent(userId)}');
      if (response is List) {
        return response
            .map((item) => GrievanceTicket.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    if (response is Map<String, dynamic>) {
      final list = response['data'] as List<dynamic>? ?? [];
      return list
          .map((item) => GrievanceTicket.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<GrievanceTicket> createGrievanceTicket(GrievanceTicket ticket) async {
    final response = await _request(
      '/grievance_tickets',
      method: 'POST',
      body: ticket.toJson(),
    );
    if (response is Map<String, dynamic>) {
      return GrievanceTicket.fromJson(response);
    }
    throw Exception('Invalid response format');
  }
}

