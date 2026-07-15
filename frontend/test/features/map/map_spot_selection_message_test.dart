import 'package:flutter_test/flutter_test.dart';
import 'package:potato_mubwanna/features/map/presentation/widget/map_spot_selection_message.dart';

void main() {
  test('reads spot id from the platform selection payload', () {
    expect(mapSpotIdFromSelectionMessage({'spotId': '42'}), '42');
  });

  test('keeps compatibility with the legacy string payload', () {
    expect(mapSpotIdFromSelectionMessage('42'), '42');
  });

  test('rejects missing or blank spot ids', () {
    expect(mapSpotIdFromSelectionMessage({'spotId': '  '}), isNull);
    expect(mapSpotIdFromSelectionMessage(null), isNull);
  });
}
