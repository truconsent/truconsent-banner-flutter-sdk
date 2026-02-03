/// Integration tests for banner flow
import 'package:flutter_test/flutter_test.dart';
import 'package:truconsent_consent_notice_flutter/src/services/banner_service.dart';
import 'package:truconsent_consent_notice_flutter/src/services/consent_manager.dart';
import 'package:truconsent_consent_notice_flutter/src/models/banner.dart';

void main() {
  group('Banner Integration', () {
    test('should handle full consent flow', () {
      // Test structure for full flow:
      // 1. Fetch banner
      // 2. Update purposes
      // 3. Submit consent
      
      final testPurposes = [
        Purpose(
          id: 'p1',
          name: 'Purpose 1',
          description: 'Test',
          isMandatory: false,
          consented: 'declined',
          expiryPeriod: '1 Year',
        ),
      ];

      // Update purpose
      final updated = updatePurposeStatus(testPurposes, 'p1', 'accepted');
      expect(updated[0].consented, 'accepted');

      // Determine action
      final action = determineConsentAction(updated);
      expect(action, ConsentAction.approved);
    });

    test('should handle accept all flow', () {
      final testPurposes = [
        Purpose(
          id: 'p1',
          name: 'Purpose 1',
          description: 'Test',
          isMandatory: false,
          consented: 'declined',
          expiryPeriod: '1 Year',
        ),
        Purpose(
          id: 'p2',
          name: 'Purpose 2',
          description: 'Test',
          isMandatory: true,
          consented: 'declined',
          expiryPeriod: '1 Year',
        ),
      ];

      // Accept all (mandatory should be auto-accepted)
      final updated = acceptMandatoryPurposes(testPurposes);
      expect(updated[1].consented, 'accepted');
    });
  });
}

