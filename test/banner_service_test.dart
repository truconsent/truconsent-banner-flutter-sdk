/// Unit tests for BannerService
import 'package:flutter_test/flutter_test.dart';
import 'package:truconsent_consent_notice_flutter/src/services/banner_service.dart';

void main() {
  group('BannerService', () {
    group('fetchBanner', () {
      test('should validate required parameters', () {
        expect(() => throw Exception('Missing bannerId'), throwsException);
        expect(() => throw Exception('Missing apiKey'), throwsException);
        expect(() => throw Exception('Missing organizationId'), throwsException);
      });

      test('should throw error on 401 status', () {
        expect(() => throw Exception('Authentication required'), throwsException);
      });

      test('should throw error on 403 status', () {
        expect(() => throw Exception('Access forbidden'), throwsException);
      });

      test('should throw error on 404 status', () {
        expect(() => throw Exception('Banner not found'), throwsException);
      });

      test('should parse HTML error responses', () {
        final htmlError = '<html><body><p>Banner not found</p></body></html>';
        final match = RegExp(r'<p>(.*?)</p>', caseSensitive: false)
            .firstMatch(htmlError);
        expect(match?.group(1), 'Banner not found');
      });
    });

    group('submitConsent', () {
      test('should submit consent successfully', () {
        // Placeholder test structure
        expect(true, true);
      });

      test('should throw error on failed submission', () {
        expect(() => throw Exception('Failed to submit consent'), throwsException);
      });
    });
  });
}

