# My Page Profile API Design

**Issue:** #37  
**Goal:** Show the authenticated user's real account identity in My Page without coupling this slice to unfinished stamp, reward, or visit data.

## Scope

The backend adds `GET /users/me`, authenticated by the existing Bearer-token filter. It returns only fields already stored in `users`: `userId`, `nickname`, `email`, `profileImage`, and `createdAt`.

The Flutter client adds a small profile data source/repository and loads it from `MyPageScreen`. The profile name and avatar use the response. A missing image keeps the existing default avatar. While loading or after a failed request, the existing static profile presentation remains visible rather than blocking logout, settings, or navigation.

## API Contract

```http
GET /users/me
Authorization: Bearer <access-token>
```

```json
{
  "success": true,
  "data": {
    "userId": 1,
    "nickname": "감자여행자",
    "email": "user@example.com",
    "profileImage": "https://example.com/profile.png",
    "createdAt": "2026-06-23T00:00:00Z"
  }
}
```

Unauthenticated requests follow the existing Spring Security response policy. The endpoint does not expose the OAuth provider identifier, refresh tokens, or other session data.

## Design Choices

1. **Recommended: identity-only API now.** It is backed by the existing `users` table and is independent of Team B's map and visit work.
2. **Rejected: include activity stats now.** Stamp, reward, potato, and walking aggregates do not yet have stable data sources, so returning fabricated or partially derived totals would make the contract brittle.
3. **Rejected: reuse the login response only.** A fresh profile endpoint handles restored sessions and later profile changes without depending on a past login screen state.

## Data Flow

1. The Flutter My Page provider requests `GET /users/me` through the existing authenticated Dio client.
2. The backend resolves the user identity from the existing JWT security context and reads that user from the repository.
3. The screen renders the API nickname and optional network avatar when available.
4. Loading and failure preserve the existing local profile placeholder so the rest of My Page stays usable.

## Tests and Verification

- Backend: authenticated request returns the stored profile fields; missing authentication is rejected by the existing security configuration.
- Flutter: loaded nickname renders; absent image uses the default avatar; request failure retains the fallback profile.
- Run backend tests, `flutter analyze`, `flutter test --no-pub`, and an Android emulator capture.

## Explicit Exclusions

- No changes to map, visit verification, favorites, missions, or Team B files.
- No user-edit, account deletion, reward, coupon, rallybook, or aggregate-stat API.
- No schema migration; the fields already exist in `users`.
