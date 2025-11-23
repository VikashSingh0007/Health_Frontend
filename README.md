# Health Tracker - Flutter App

Flutter mobile application for tracking health data using Google Fit integration.

## Features

- 🔐 Google Sign-In authentication
- 📊 Health dashboard with steps, calories, heart rate
- 📈 Weekly history charts
- 🔄 Pull-to-refresh data
- 🔄 Automatic data sync with Google Fit

## Prerequisites

- Flutter SDK (3.8.1 or higher)
- Android Studio / Xcode (for mobile development)
- Backend server running (see `../health-backend/README.md`)

## Setup

### 1. Install Dependencies

```bash
cd frontend
flutter pub get
```

### 2. Configure Backend URL

Edit `lib/utils/constants.dart` and update the base URL if your backend is not running on `localhost:3000`:

```dart
static const String baseUrl = 'http://your-backend-url:3000';
```

**For Android Emulator:** Use `http://10.0.2.2:3000` instead of `localhost:3000`

**For iOS Simulator:** Use `http://localhost:3000`

**For Physical Device:** Use your computer's IP address, e.g., `http://192.168.1.100:3000`

### 3. Configure Google Sign-In

#### Android Setup

1. Get SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Or:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. Go to [Google Cloud Console](https://console.cloud.google.com)
3. Navigate to: **APIs & Services** → **Credentials**
4. Edit your **Android** OAuth 2.0 Client ID
5. Add the SHA-1 fingerprint
6. Package name should be: `com.example.frontend` (or your package name)

#### iOS Setup

1. Get Bundle ID from `ios/Runner.xcodeproj` (should be `com.example.frontend`)
2. Go to [Google Cloud Console](https://console.cloud.google.com)
3. Navigate to: **APIs & Services** → **Credentials**
4. Edit your **iOS** OAuth 2.0 Client ID
5. Ensure Bundle ID matches

### 4. Run the App

```bash
# For Android
flutter run

# For iOS
flutter run

# For specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

## Project Structure

```
lib/
├── models/              # Data models
│   ├── user_model.dart
│   ├── auth_response.dart
│   └── health_data_model.dart
├── services/            # API and auth services
│   ├── auth_service.dart
│   └── api_service.dart
├── screens/            # UI screens
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   └── history_screen.dart
├── providers/          # State management
│   └── health_provider.dart
├── widgets/           # Reusable widgets
├── utils/             # Constants and helpers
│   └── constants.dart
└── main.dart          # App entry point
```

## Usage

### 1. Login

- Open the app
- Tap "Sign in with Google"
- Complete Google authentication
- Grant Google Fit permissions

### 2. View Dashboard

- See today's steps, calories, heart rate
- Tap "Refresh Data" to fetch latest from Google Fit
- Pull down to refresh

### 3. View History

- Tap "View History" button
- See weekly steps chart
- View daily records

## Troubleshooting

### Google Sign-In Not Working

**Error:** "Sign in failed" or "PlatformException"

**Solutions:**
1. Verify SHA-1 fingerprint is added to Google Cloud Console
2. Check package name matches in `build.gradle.kts` and Google Cloud Console
3. Ensure Google Sign-In package is properly configured

### Cannot Connect to Backend

**Error:** "Connection refused" or network error

**Solutions:**
1. **Android Emulator:** Use `http://10.0.2.2:3000` instead of `localhost:3000`
2. **iOS Simulator:** `localhost:3000` should work
3. **Physical Device:** 
   - Find your computer's IP: `ifconfig` (Mac/Linux) or `ipconfig` (Windows)
   - Use: `http://YOUR_IP:3000`
   - Ensure phone and computer are on same network
4. Verify backend is running: `curl http://localhost:3000/auth/profile`

### No Health Data Showing

**Solutions:**
1. Tap "Refresh Data" button to fetch from Google Fit
2. Ensure you have Google Fit data synced
3. Check backend logs for errors
4. Verify JWT token is valid

## Development

### Hot Reload

Press `r` in the terminal or click the hot reload button in your IDE.

### Build for Release

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## API Integration

The app communicates with the NestJS backend:

- **Authentication:** `POST /auth/google/mobile`
- **Fetch Health Data:** `POST /health/fetch`
- **Get Dashboard:** `GET /health/dashboard`
- **Get History:** `GET /health/history`

All requests (except login) require JWT token in Authorization header.

## Next Steps

- Add more health metrics
- Implement push notifications
- Add goal setting
- Improve UI/UX
- Add offline support
