import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/application/map_spot_controller.dart'
    as map;
import 'package:potato_mubwanna/features/spot/application/spot_detail_controller.dart'
    as detail;
import 'package:potato_mubwanna/features/spot/data/spot_detail_repository.dart';

void main() {
  test('map and detail share one in-flight full response', () async {
    final pending = Completer<Map<String, dynamic>>();
    final repository = _Repository((id, basic) => pending.future);
    final container = ProviderContainer(overrides: [
      detail.spotDetailRepositoryProvider.overrideWithValue(repository)
    ]);
    addTearDown(container.dispose);
    final first = container.read(map.spotDetailProvider('7').future);
    final second = container.read(detail.spotDetailProvider('7').future);
    expect(repository.fullCalls, 1);
    pending.complete(_payload('7'));
    expect((await first).name, 'saved place');
    expect((await second).name, 'saved place');
    expect(repository.fullCalls, 1);
  });

  test('keeps the full request alive between screens before it completes',
      () async {
    final pending = Completer<Map<String, dynamic>>();
    final repository = _Repository((id, basic) => pending.future);
    final container = ProviderContainer(overrides: [
      detail.spotDetailRepositoryProvider.overrideWithValue(repository)
    ]);
    addTearDown(container.dispose);
    final subscription =
        container.listen(map.spotDetailProvider('7'), (_, __) {});
    subscription.close();
    await container.pump();
    final detailFuture = container.read(detail.spotDetailProvider('7').future);
    pending.complete(_payload('7'));
    expect((await detailFuture).name, 'saved place');
    expect(repository.fullCalls, 1);
  });

  test('keeps a successful response between map and detail navigation',
      () async {
    final repository = _Repository((id, basic) async => _payload(id));
    final container = ProviderContainer(overrides: [
      detail.spotDetailRepositoryProvider.overrideWithValue(repository)
    ]);
    addTearDown(container.dispose);
    final subscription =
        container.listen(map.spotDetailProvider('7'), (_, __) {});
    await container.read(map.spotDetailProvider('7').future);
    subscription.close();
    await container.pump();
    expect(
        (await container.read(detail.spotDetailProvider('7').future)).id, '7');
    expect(repository.fullCalls, 1);
    await container.read(detail.spotDetailProvider('8').future);
    expect(repository.fullCalls, 2);
  });

  testWidgets('success cache expires after two minutes without listeners',
      (tester) async {
    final repository = _Repository((id, basic) async => _payload(id));
    final container = ProviderContainer(overrides: [
      detail.spotDetailRepositoryProvider.overrideWithValue(repository)
    ]);

    var subscription =
        container.listen(detail.spotDetailProvider('7'), (_, __) {});
    await tester.pump();
    await container.read(detail.spotDetailProvider('7').future);
    subscription.close();
    await tester.pump();
    await tester.pump(const Duration(minutes: 2, seconds: 1));
    subscription = container.listen(detail.spotDetailProvider('7'), (_, __) {});
    await tester.pump();
    expect(repository.fullCalls, 2);
    subscription.close();
    container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });

  test('failed responses can be explicitly retried without poisoning cache',
      () async {
    var failed = true;
    final repository = _Repository((id, basic) async {
      if (failed) throw StateError('offline');
      return _payload(id);
    });
    final container = ProviderContainer(overrides: [
      detail.spotDetailRepositoryProvider.overrideWithValue(repository)
    ]);
    addTearDown(container.dispose);
    final subscription =
        container.listen(detail.spotDetailProvider('7'), (_, __) {});
    addTearDown(subscription.close);
    await expectLater(container.read(detail.spotDetailProvider('7').future),
        throwsStateError);
    failed = false;
    container.invalidate(detail.spotDetailResponseProvider('7'));
    expect((await container.read(detail.spotDetailProvider('7').future)).name,
        'saved place');
    expect(repository.fullCalls, 2);
  });

  test('basic response cannot satisfy or overwrite the full response cache',
      () async {
    final repository = _Repository((id, basic) async =>
        {..._payload(id), 'description': basic ? null : 'full description'});
    final container = ProviderContainer(overrides: [
      detail.spotDetailRepositoryProvider.overrideWithValue(repository)
    ]);
    addTearDown(container.dispose);
    expect(
        (await container.read(detail.spotBasicDetailProvider('7').future))
            .description,
        isNull);
    expect(
        (await container.read(detail.spotDetailProvider('7').future))
            .description,
        'full description');
    expect(repository.basicCalls, 1);
    expect(repository.fullCalls, 1);
  });
}

Map<String, dynamic> _payload(String id) => {'id': id, 'name': 'saved place'};

class _Repository extends SpotDetailRepository {
  _Repository(this.load) : super(dio: Dio());
  final Future<Map<String, dynamic>> Function(String, bool) load;
  int fullCalls = 0;
  int basicCalls = 0;
  @override
  Future<Map<String, dynamic>> fetchSpotDetailPayload(String id,
      {bool basic = false}) {
    if (basic) {
      basicCalls++;
    } else {
      fullCalls++;
    }
    return load(id, basic);
  }
}
