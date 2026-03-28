# Invoice Generator - Mobile App

Flutter mobile app (iOS & Android) for the Invoice Generator system. Companion to the [web dashboard](https://invoice.digitlock.systems), consuming the same REST API.

## Features

- Invoice creation, history, status management, PDF download
- Client management (view, create, edit status)
- Read-only company & bank account viewing
- JWT authentication (shared with Expense Tracker)

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run in development
flutter run --dart-define=API_URL=http://localhost:8081

# Run in production
flutter run --dart-define=API_URL=https://invoice.digitlock.systems
```

## Build

```bash
# Android APK
flutter build apk --release --dart-define=API_URL=https://invoice.digitlock.systems

# iOS
flutter build ipa --dart-define=API_URL=https://invoice.digitlock.systems
```

## Documentation

See [Documentation/invoice-generator-mobile-srs.md](Documentation/invoice-generator-mobile-srs.md) for full SRS.
