/// Unit tests for ConsentManager
import 'package:flutter_test/flutter_test.dart';
import 'package:truconsent_consent_banner_flutter/src/services/consent_manager.dart';
import 'package:truconsent_consent_banner_flutter/src/models/banner.dart';

void main() {
  group('ConsentManager', () {
    final testPurposes = [
      Purpose(
        id: 'p1',
        name: 'Purpose 1',
        description: 'Test purpose 1',
        isMandatory: false,
        consented: 'declined',
        expiryPeriod: '1 Year',
      ),
      Purpose(
        id: 'p2',
        name: 'Purpose 2',
        description: 'Test purpose 2',
        isMandatory: true,
        consented: 'declined',
        expiryPeriod: '1 Year',
      ),
    ];

    group('updatePurposeStatus', () {
      test('should update purpose status correctly', () {
        final updated = updatePurposeStatus(testPurposes, 'p1', 'accepted');
        expect(updated[0].consented, 'accepted');
        expect(updated[1].consented, 'declined');
      });

      test('should not affect other purposes', () {
        final updated = updatePurposeStatus(testPurposes, 'p1', 'accepted');
        expect(updated.length, 2);
        expect(updated[1].id, 'p2');
      });
    });

    group('acceptMandatoryPurposes', () {
      test('should accept all mandatory purposes', () {
        final updated = acceptMandatoryPurposes(testPurposes);
        expect(updated[1].consented, 'accepted');
        expect(updated[0].consented, 'declined');
      });
    });

    group('determineConsentAction', () {
      test('should return approved when all purposes accepted', () {
        final allAccepted = testPurposes.map((p) => Purpose(
              id: p.id,
              name: p.name,
              description: p.description,
              isMandatory: p.isMandatory,
              consented: 'accepted',
              expiryPeriod: p.expiryPeriod,
            )).toList();
        final action = determineConsentAction(allAccepted);
        expect(action, ConsentAction.approved);
      });

      test('should return declined when all purposes declined', () {
        final action = determineConsentAction(testPurposes);
        expect(action, ConsentAction.declined);
      });

      test('should return partialConsent for mixed states', () {
        final mixed = [
          Purpose(
            id: 'p1',
            name: 'Purpose 1',
            description: 'Test',
            isMandatory: false,
            consented: 'accepted',
            expiryPeriod: '1 Year',
          ),
          Purpose(
            id: 'p2',
            name: 'Purpose 2',
            description: 'Test',
            isMandatory: false,
            consented: 'declined',
            expiryPeriod: '1 Year',
          ),
        ];
        final action = determineConsentAction(mixed);
        expect(action, ConsentAction.partialConsent);
      });
    });

    group('getAcceptedPurposes', () {
      test('should return only accepted purposes', () {
        final mixed = [
          Purpose(
            id: 'p1',
            name: 'Purpose 1',
            description: 'Test',
            isMandatory: false,
            consented: 'accepted',
            expiryPeriod: '1 Year',
          ),
          Purpose(
            id: 'p2',
            name: 'Purpose 2',
            description: 'Test',
            isMandatory: false,
            consented: 'declined',
            expiryPeriod: '1 Year',
          ),
        ];
        final accepted = getAcceptedPurposes(mixed);
        expect(accepted.length, 1);
        expect(accepted[0].id, 'p1');
      });
    });

    group('hasMandatoryPurposes', () {
      test('should return true when mandatory purposes exist', () {
        expect(hasMandatoryPurposes(testPurposes), true);
      });

      test('should return false when no mandatory purposes', () {
        final optionalOnly = testPurposes
            .map((p) => Purpose(
                  id: p.id,
                  name: p.name,
                  description: p.description,
                  isMandatory: false,
                  consented: p.consented,
                  expiryPeriod: p.expiryPeriod,
                ))
            .toList();
        expect(hasMandatoryPurposes(optionalOnly), false);
      });
    });
  });
}

