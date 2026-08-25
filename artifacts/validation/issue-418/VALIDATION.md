# Issue 418 Validation

## Scope

- Map discovery home travel course cards were refined into a more image-led editorial layout.
- Travel course details now open as a full blog-style route page instead of a compact bottom sheet.
- Existing full Kakao map entry, route saving, route mode, place detail, category filter, and navigation behavior were preserved.
- Follow-up fixes keep travel course cards shorter, use a broader course image selection from API-backed `imageUrl` data, and normalize course detail stop images to one landscape ratio.

## Changed Files

- `frontend/lib/features/map/data/travel_course_catalog.dart`
- `frontend/lib/features/map/presentation/screen/map_screen.dart`
- `frontend/test/features/map/travel_course_catalog_test.dart`
- `frontend/test/features/map/map_screen_test.dart`

## Verification

- `frontend`: `/Users/mac/Documents/flutter/bin/flutter analyze`
  - Result: PASS
- `frontend`: `/Users/mac/Documents/flutter/bin/flutter test test/features/map/travel_course_catalog_test.dart test/features/map/map_screen_test.dart`
  - Result: PASS
- `frontend`: `/Users/mac/Documents/flutter/bin/flutter test`
  - Result: PASS
- `frontend`: `/Users/mac/Documents/flutter/bin/flutter test test/features/map/travel_course_catalog_test.dart test/features/map/map_screen_test.dart`
  - Result: PASS after follow-up course image/card ratio fixes.
- `frontend`: `/Users/mac/Documents/flutter/bin/flutter analyze`
  - Result: PASS after follow-up course image/card ratio fixes.

## Notes

- This issue changed Flutter UI only; backend API and DB contracts were not changed.
- Real Kakao map rendering, native location recentering, and actual image loading should still be smoke-tested on a device/simulator because widget tests use a stub map.
- `frontend/ios/Podfile.lock` has an unrelated local modification and was intentionally not touched or staged for this issue.
