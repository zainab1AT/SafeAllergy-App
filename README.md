# SafeAllergy

**SafeAllergy** is a Flutter application for **emergency patient management**, designed for fast access to critical patient allergy/medical information using **NFC tags** and **QR codes**.

### Key Features

- **Read patient data**
  - Read from **NFC tag**
  - Scan from **QR code** (camera) and **QR from gallery image**
- **Write patient data to NFC**
  - Protected by **authorized email** verification
- **Cloud backend (Firebase)**
  - Patient profiles stored in **Cloud Firestore**
  - **Audit logging** for read/write events
- **Modern Flutter UI**
  - Material 3 styling
  - BLoC state management (`flutter_bloc`)

### Screenshots

Add your screenshots to a folder like `screenshots/` and update the paths below:

| Home                          | Read NFC / QR                 | Patient Details                     |
| ----------------------------- | ----------------------------- | ----------------------------------- |
| ![Home](screenshots/home.png) | ![Read](screenshots/read.png) | ![Details](screenshots/details.png) |

### Tech Stack

- **Flutter / Dart**
- **State management**: `flutter_bloc`
- **Firebase**: `firebase_core`, `cloud_firestore`, `firebase_auth`
- **NFC**: `flutter_nfc_kit`
- **QR**: `mobile_scanner`, `qr_flutter`, `google_mlkit_barcode_scanning`

### Project Structure (high-level)

- `lib/pages/` — screens (home, NFC read/write, QR scan, patient details, auth)
- `lib/bloc/` — BLoC/Cubit state management
- `lib/services/` — NFC/QR/Firebase services
- `assets/images/` — app assets

### Setup (minimal)

This repo is configured to **not commit project-specific config/secrets** (see `.gitignore`).

- **Flutter**: install Flutter SDK and run:

```bash
flutter pub get
flutter run
```

- **Firebase**: provide your own Firebase project configuration (not committed):
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

### License

Proprietary — all rights reserved. Replace this section with your preferred license text.
