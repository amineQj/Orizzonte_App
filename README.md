# ORIZZONTE (Flutter client)

## Backend URL configuration

Development defaults are built in:

- Android emulator: `http://10.0.2.2:8000`
- Other platforms (desktop/web/simulator): `http://127.0.0.1:8000`

Override them with a Dart define:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

Release builds **require** an HTTPS URL and fail fast at startup:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

Cleartext/local-network access is enabled only in debug platform manifests. No
ATS exception or Android cleartext flag is present in release configuration.

## Authentication storage

Access and refresh tokens are stored in platform-secure storage. Legacy
SharedPreferences auth values are migrated once and removed. Sign-out performs
a best-effort backend logout, then clears both tokens locally.

## Tests

```powershell
flutter pub get
flutter analyze
flutter test
```
