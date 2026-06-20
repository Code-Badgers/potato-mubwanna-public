# Travel Record Screen Design

## Goal

Provide a reachable travel-record screen from My Page so users can review the
places they have visited and the stamps they acquired.

## Scope

- Add a standalone `TravelRecordScreen` under the user-domain presentation
  layer.
- Render local mock records with a visit date, city, tourist spot, and stamp
  acquisition state.
- Add a `/travel-records` route outside the main shell.
- Navigate from the My Page `여행 기록` quick action with `context.push`.
- Provide an in-screen back button that returns to My Page.
- Cover route navigation, record rendering, and back navigation with widget
  tests.

## UI And Data Flow

The screen uses the existing warm background, compact header, and 8px card
radius conventions. A summary at the top shows the number of visited places;
the scrollable list below uses date-grouped records. Each record presents the
city, spot name, and a clear acquired-stamp indicator.

Records remain local immutable mock data for this issue. A later data source
can replace the list with `GET /api/users/me/visits` without changing routing
or the screen's UI boundary.

## Excluded Work

- Backend or API-contract changes.
- Map, spot-detail, visit-verification, mission, and potato-domain changes.
- Pagination, filtering, and record-detail navigation.

## Error And Empty States

The local mock-data scope has no remote loading or error state. The list UI is
structured so a future API integration can add loading, error, and empty
states without changing the My Page navigation contract.

## Verification

- Add a widget test proving that My Page opens `/travel-records` and that the
  route can be popped back to My Page.
- Add a widget test for the travel-record content and its back control.
- Run `flutter analyze` and `flutter test --no-pub`.
