# Issue #428 Validation

## Scope

- Added a shared Flutter loading UI using `frontend/assets/loading/loading.png`.
- Split the source sheet into eight transparent potato character frames.
- Applied the shared loading UI only to large/full-screen loading states:
  - Map loading
  - Stamp tour loading
  - Passport loading
  - Mission loading
  - Potato field loading
  - Travel record loading
  - My page loading overlay
- Kept small inline/button/image loading indicators unchanged.

## Assets

- Source: `frontend/assets/loading/loading.png`
- Frames:
  - `frontend/assets/loading/potato_loading_01.png`
  - `frontend/assets/loading/potato_loading_02.png`
  - `frontend/assets/loading/potato_loading_03.png`
  - `frontend/assets/loading/potato_loading_04.png`
  - `frontend/assets/loading/potato_loading_05.png`
  - `frontend/assets/loading/potato_loading_06.png`
  - `frontend/assets/loading/potato_loading_07.png`
  - `frontend/assets/loading/potato_loading_08.png`

## Animation

- Playback order: `1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 7 -> 6 -> 5 -> 4 -> 3 -> 2`
- Frame interval: `220ms`
- The widget preloads all frames and disposes the timer on unmount.
- Accessibility label: `콘텐츠를 불러오는 중`

## Validation Commands

- `flutter analyze`
  - PASS
- `flutter test --reporter compact test/shared/widgets/loading/potato_loading_view_test.dart test/features/potato/potato_collection_screen_test.dart test/features/stamp/stamp_book_screen_test.dart`
  - PASS
- `flutter test --reporter compact`
  - PASS

## Notes

- A first full test run exposed an intrinsic layout issue when the loading widget was embedded in a sliver-based screen. The widget no longer uses `LayoutBuilder`, so it is safe in those contexts.
- `frontend/pubspec.yaml` was updated to include `assets/loading/`; this is a shared frontend asset registry file.
- Real device/simulator visual timing should still be checked once merged because animation feel is subjective.
