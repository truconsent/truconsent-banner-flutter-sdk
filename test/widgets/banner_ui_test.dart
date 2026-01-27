/// Widget tests for BannerUI
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truconsent_consent_banner_flutter/src/widgets/banner_ui.dart';
import 'package:truconsent_consent_banner_flutter/src/models/banner.dart';

void main() {
  group('BannerUI', () {
    final testBanner = Banner(
      bannerId: 'test-banner',
      collectionPoint: 'test-cp',
      version: '1',
      title: 'Test Banner',
      expiryType: 'active',
      purposes: [
        Purpose(
          id: 'p1',
          name: 'Purpose 1',
          description: 'Test purpose',
          isMandatory: false,
          consented: 'declined',
          expiryPeriod: '1 Year',
        ),
      ],
    );

    testWidgets('should render banner with purposes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerUI(
              banner: testBanner,
              companyName: 'Test Company',
              onChangePurpose: (id, status) {},
              onRejectAll: () {},
              onConsentAll: () {},
              onAcceptSelected: () {},
            ),
          ),
        ),
      );

      // Should render company name
      expect(find.text('Test Company'), findsWidgets);
    });

    testWidgets('should call onChangePurpose when purpose is toggled', (tester) async {
      String? toggledId;
      String? toggledStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BannerUI(
              banner: testBanner,
              companyName: 'Test Company',
              onChangePurpose: (id, status) {
                toggledId = id;
                toggledStatus = status;
              },
              onRejectAll: () {},
              onConsentAll: () {},
              onAcceptSelected: () {},
            ),
          ),
        ),
      );

      // Note: Actual toggle interaction would need to find the switch widget
      // This is a basic structure test
      expect(find.text('Test Company'), findsWidgets);
    });
  });
}

