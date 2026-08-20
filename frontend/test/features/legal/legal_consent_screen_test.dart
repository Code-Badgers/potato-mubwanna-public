import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/legal/data/legal_consent_store.dart';
import 'package:potato_mubwanna/features/legal/presentation/screen/legal_consent_screen.dart';

void main() {
  testWidgets('requires minimum age confirmation and service terms',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _RecordingLegalConsentStore();
    var acceptedCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: LegalConsentScreen(
          consentStore: store,
          onAccepted: () async => acceptedCalls++,
        ),
      ),
    );

    final continueButton =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, '계속하기'));
    expect(continueButton.onPressed, isNull);

    await tester.tap(find.text('서비스 이용약관'));
    await tester.pump();
    final serviceTermsOnlyButton =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, '계속하기'));
    expect(serviceTermsOnlyButton.onPressed, isNull);

    await tester.tap(find.text('만 14세 이상입니다'));
    await tester.pump();
    await tester.tap(find.text('개인위치정보 이용 동의'));
    await tester.pump();
    await tester.tap(find.text('계속하기'));
    await tester.pumpAndSettle();

    expect(store.requiredAcceptCalls, 1);
    expect(store.locationValues, [true]);
    expect(store.healthValues, [false]);
    expect(acceptedCalls, 1);
  });

  testWidgets('all agreement includes every optional consent', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _RecordingLegalConsentStore();

    await tester.pumpWidget(
      MaterialApp(
        home: LegalConsentScreen(
          consentStore: store,
          onAccepted: () async {},
        ),
      ),
    );
    await tester.tap(find.text('전체 동의'));
    await tester.pump();
    final continueButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '계속하기'),
    );
    expect(continueButton.onPressed, isNotNull);
    await tester.tap(find.text('계속하기'));
    await tester.pumpAndSettle();

    expect(store.locationValues, [true]);
    expect(store.healthValues, [true]);
  });
}

class _RecordingLegalConsentStore implements LegalConsentStore {
  int requiredAcceptCalls = 0;
  final locationValues = <bool>[];
  final healthValues = <bool>[];

  @override
  Future<void> acceptRequiredDocuments() async => requiredAcceptCalls++;

  @override
  Future<bool> hasAcceptedHealthData() async => false;

  @override
  Future<bool> hasAcceptedPersonalLocation() async => false;

  @override
  Future<bool> hasAcceptedRequiredDocuments() async => false;

  @override
  Future<void> setHealthDataConsent(bool accepted) async {
    healthValues.add(accepted);
  }

  @override
  Future<void> setPersonalLocationConsent(bool accepted) async {
    locationValues.add(accepted);
  }
}
