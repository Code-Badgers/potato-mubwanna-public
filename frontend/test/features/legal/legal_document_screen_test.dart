import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/legal/data/legal_consent_store.dart';
import 'package:potato_mubwanna/features/legal/domain/legal_document.dart';
import 'package:potato_mubwanna/features/legal/domain/legal_document_catalog.dart';
import 'package:potato_mubwanna/features/legal/presentation/screen/legal_document_screen.dart';

void main() {
  testWidgets('renders the location terms and manages separate consent',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _MutableLegalConsentStore();
    var synchronizationCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: LegalDocumentScreen(
          document: LegalDocumentCatalog.document(
            LegalDocumentType.locationServiceTerms,
          ),
          manageConsent: true,
          consentStore: store,
          onConsentChanged: () async => synchronizationCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('위치기반서비스 이용약관'), findsOneWidget);
    expect(find.text('제3조 위치기반서비스의 내용과 요금'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('제9조 이용 연령'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('제9조 이용 연령'), findsOneWidget);
    expect(find.text('동의하기'), findsOneWidget);

    await tester.tap(find.text('동의하기'));
    await tester.pumpAndSettle();

    expect(store.locationAccepted, isTrue);
    expect(synchronizationCalls, 1);
    expect(find.text('동의 철회하기'), findsOneWidget);
  });

  testWidgets('privacy policy discloses location and health processing',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LegalDocumentScreen(
          document: LegalDocumentCatalog.document(
            LegalDocumentType.privacyPolicy,
          ),
        ),
      ),
    );

    expect(find.text('개인정보처리방침'), findsOneWidget);
    expect(find.text('2. 처리 목적·항목·보유기간'), findsOneWidget);
    expect(
      find.textContaining('만 14세 미만 아동의 개인정보와 개인위치정보를 수집하지 않습니다'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('3. 개인위치정보 처리'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('3. 개인위치정보 처리'), findsOneWidget);
  });

  testWidgets('service terms disclose the minimum age policy', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LegalDocumentScreen(
          document: LegalDocumentCatalog.document(
            LegalDocumentType.serviceTerms,
          ),
        ),
      ),
    );

    expect(find.text('제5조 이용 연령'), findsOneWidget);
    expect(find.textContaining('만 14세 미만인 경우'), findsOneWidget);
  });
}

class _MutableLegalConsentStore implements LegalConsentStore {
  bool locationAccepted = false;

  @override
  Future<void> acceptRequiredDocuments() async {}

  @override
  Future<bool> hasAcceptedHealthData() async => false;

  @override
  Future<bool> hasAcceptedPersonalLocation() async => locationAccepted;

  @override
  Future<bool> hasAcceptedRequiredDocuments() async => true;

  @override
  Future<void> setHealthDataConsent(bool accepted) async {}

  @override
  Future<void> setPersonalLocationConsent(bool accepted) async {
    locationAccepted = accepted;
  }
}
