# Flutter App Setup Guide

## Quick Setup Steps

### 1. Install Dependencies

```bash
cd frontend
flutter pub get
```

### 2. Update Backend URL

Edit `lib/utils/constants.dart`:

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:3000';
```

**For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:3000';
```

**For Physical Device:**
```dart
// Find your computer's IP address first
static const String baseUrl = 'http://192.168.1.XXX:3000';
```

### 3. Get SHA-1 Fingerprint (Android)

```bash
cd android
./gradlew signingReport
```

Copy the SHA-1 from the output (look for `SHA1:` under `Variant: debug`)

### 4. Add SHA-1 to Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to: **APIs & Services** → **Credentials**
3. Click on your **Android** OAuth 2.0 Client ID
4. Add the SHA-1 fingerprint
5. Save

### 5. Run the App

```bash
flutter run
```

## Testing Checklist

- [ ] Dependencies installed (`flutter pub get`)
- [ ] Backend URL configured correctly
- [ ] SHA-1 fingerprint added to Google Cloud Console
- [ ] Backend server is running
- [ ] App launches without errors
- [ ] Google Sign-In works
- [ ] Dashboard loads data
- [ ] Refresh data works
- [ ] History screen shows chart

## Common Issues

### Issue: "Connection refused"

**Solution:** Check backend URL in `constants.dart`:
- Android Emulator: `http://10.0.2.2:3000`
- iOS Simulator: `http://localhost:3000`
- Physical Device: Your computer's IP address

### Issue: Google Sign-In fails

**Solution:**
1. Verify SHA-1 is added to Google Cloud Console
2. Check package name matches: `com.example.frontend`
3. Wait a few minutes after adding SHA-1 (Google needs time to propagate)

### Issue: No data showing

**Solution:**
1. Tap "Refresh Data" button
2. Check backend is running
3. Verify you're logged in
4. Check backend logs for errors

