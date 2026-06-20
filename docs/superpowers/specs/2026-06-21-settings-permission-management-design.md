# Settings Permission Management Design

## Goal

Provide a My Page settings screen where users can inspect and manage the
location and notification permissions required by the MVP.

## Scope

- Add a standalone `SettingsScreen` with location and notification permission
  rows.
- Extend `PermissionService` with status lookup and app-settings navigation
  methods in addition to its existing request methods.
- Render the permission state as `허용됨`, `허용 필요`, or `설정에서 허용 필요`.
- Request a denied permission from the corresponding row.
- Open system app settings only for permanently denied or restricted states.
- Add Android manifest entries for coarse location, fine location, and
  notifications because the existing manifest declares only internet access.
- Add `/settings` outside the main shell and connect both My Page settings
  entry points: the header icon and the account-menu settings row.

## UI And Data Flow

`SettingsScreen` loads the two statuses through an injected `PermissionService`
instance. The production route creates the default service; tests supply a fake
service, keeping native permission calls outside widget tests.

Each row shows an icon, permission name, short purpose, current state, and one
contextual action. After a successful request, the screen reloads the status.
The header back control pops when a route exists and otherwise goes to
`/main/mypage`, matching the direct-entry fallback used by travel records.

## Android Configuration

The Android manifest will declare:

- `android.permission.ACCESS_COARSE_LOCATION`
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.POST_NOTIFICATIONS`

No camera, media, contacts, or other permissions are added. iOS configuration
is excluded because this MVP validation target is Android.

## Excluded Work

- Account profile editing, member withdrawal, terms, notices, and customer
  support.
- Backend APIs, database migrations, or token changes.
- Map visit verification and all Team B domain files.

## Error Handling And Testing

If status lookup or a permission request fails, the screen preserves the last
known state and displays a retry action. Widget tests cover initial states,
request action state refresh, permanently denied app-settings navigation, and
both My Page entry points. Android compilation validates manifest syntax.
