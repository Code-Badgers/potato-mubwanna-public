# Potato Mubwanna Frontend

Flutter mobile app for the Potato Mubwanna location-based stamp rally service.

## Stack

- Flutter 3.x
- Dart
- Riverpod
- GoRouter
- Dio
- Kakao Map
- Firebase Cloud Messaging
- Flutter Secure Storage

## Structure

```txt
lib/
  app/
  core/
  features/
  shared/
```

## Commands

```bash
flutter pub get
flutter analyze
flutter test
```

### API endpoint for Android Studio runs

Flutter does not automatically load the ignored `frontend/.env` file. A plain
Android Studio run therefore uses the deployed API by default so the map can
load the same spot images and business details as the release environment.

To use a backend running on this computer, explicitly override the build-time
value:

```bash
flutter run -d <device> \
  --dart-define=API_BASE_URL=http://localhost:8080/api
```

After changing a `--dart-define` value, stop and run the app again. Hot reload
does not replace compile-time environment constants.

### Legal notice configuration

Copy `.env.example` to the ignored `frontend/.env` and fill every `LEGAL_*`
value before a release build. The real registration number, home-office
address, phone number, and email must not be committed. A release build must
receive the file through `--dart-define-from-file=frontend/.env`; Gradle rejects
the build when a required legal value is missing.

### Kakao Map on a Windows Android emulator

The Kakao Maps native engine included in this project does not provide an
`x86_64` library. A normal `flutter run` therefore installs an x86_64 app on a
typical Windows emulator and leaves the map area blank.

If the emulator reports `arm64-v8a` in its supported ABI list, build and install
the app through Android's ARM64 translation layer instead:

```powershell
.\tool\run_android_arm64_emulator.ps1 -DeviceId emulator-5554
```

The script reads `frontend/.env` without printing its values, builds an ARM64
debug APK, replaces the installed app while preserving its data, verifies the
selected ABI, connects an emulator `localhost` API URL to the local backend,
and starts the app. It looks for `flutter` and `adb` on `PATH` and in the common
Windows SDK locations. Explicit paths can also be supplied:

```powershell
.\tool\run_android_arm64_emulator.ps1 `
  -DeviceId emulator-5554 `
  -FlutterPath C:\src\flutter\bin\flutter.bat `
  -AdbPath C:\Android\Sdk\platform-tools\adb.exe
```

Run the script again after source changes. A subsequent normal `flutter run`
can replace the app with an x86_64 build and reproduce the blank map.
