# Issue #434 Validation

## Scope

Stabilize map spot images and supporting place information for the discovery cards and the full-map selected-spot sheet. Existing response fields are preserved: `imageUrl`, `imageUrls`, `businessOpeningHours`, `menuItems`, and the detail TourAPI fields.

## Changes validated

- Curated/non-numeric spot references are matched to TourAPI items by place name, city, address, and coordinates.
- TourAPI image fallback now uses the resolved reference and writes the first successful image through the existing image cache writer.
- TourAPI detail information uses the same resolved reference and remains non-critical when the external service is unavailable.
- Google enrichment is attempted for tourism, experience, market, and shop categories in addition to food and drink categories.
- Discovery cards render the server-provided image, address, today's hours, and the first server-provided menu item when available.
- Existing source precedence remains DB image, Google image, TourAPI image, then the Flutter placeholder.

## Commands

| Command | Result |
| --- | --- |
| `cd backend && ./gradlew test --no-daemon` | PASS, build successful; Gradle reports all backend tests passed |
| `cd frontend && /Users/mac/Documents/flutter/bin/flutter analyze` | PASS, no issues found |
| `cd frontend && /Users/mac/Documents/flutter/bin/flutter test` | PASS, 327 tests passed |
| `/Users/mac/Documents/flutter/bin/dart format --output=none lib/features/map/presentation/screen/map_screen.dart test/features/map/map_screen_test.dart` | PASS, both files already formatted |
| `git diff --check` | PASS |

## Targeted coverage

- Curated TourAPI reference resolution success.
- Weak TourAPI match rejection.
- Numeric TourAPI content ID direct resolution without keyword search.
- TourAPI image fallback through a resolved curated reference.
- TourAPI keyword search delegation.
- Google enrichment for a matched tourism spot.
- Discovery card rendering for image, address, hours, and menu data is covered by the existing map screen widget setup and model parsing tests.

## Runtime notes

The production `/api/spots` response was inspected before this branch was deployed. Several curated places returned empty image and menu fields at that time, which is the issue being addressed here. The fix must be merged and deployed before production responses change.

The local backend environment has a configured TourAPI service key but no configured Google Places key. Google image, phone, and opening-hours enrichment therefore remains unverified locally and requires the deployment environment to provide its secret without exposing it in source control or logs.

External enrichment failures are intentionally non-fatal. A missing key, timeout, HTTP error, or unmatched place keeps the spot response available and falls back to stored data or the frontend placeholder.

## Remaining device/production checks

1. Deploy the branch and confirm curated spots return non-empty `imageUrl`/`imageUrls` where TourAPI has a matching image.
2. Configure the server-side Google Places secret and verify matched food/drink spots return cached image and business information.
3. Open the discovery card and full-map sheet on iOS and Android and verify real image loading, expanded sheet content, and fallback behavior with a deliberately unavailable image.
