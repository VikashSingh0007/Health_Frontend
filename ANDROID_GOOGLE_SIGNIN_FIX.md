# Fix Google Sign-In Error on Android

## Error
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.Api10:, null, null)
```

This error occurs when Google Sign-In is not properly configured for Android.

## Solution: Add SHA-1 Fingerprint

### Step 1: Get SHA-1 Fingerprint

**Option A: Using Gradle (Recommended)**
```bash
cd frontend/android
./gradlew signingReport
```

Look for output like:
```
Variant: debug
Config: debug
Store: ~/.android/debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**Option B: Using keytool directly**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy the SHA-1 value (the long string of hex characters separated by colons).

### Step 2: Add SHA-1 to Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. Navigate to: **APIs & Services** → **Credentials**
4. Find your **Android** OAuth 2.0 Client ID (or create one if it doesn't exist)
5. Click **Edit** (pencil icon)
6. Under **SHA-1 certificate fingerprints**, click **+ ADD SHA-1**
7. Paste your SHA-1 fingerprint
8. Click **SAVE**

### Step 3: Verify Package Name

Make sure the package name in Google Cloud Console matches:
- Package name: `com.example.frontend`
- This should match `applicationId` in `android/app/build.gradle.kts`

### Step 4: Wait and Retry

- Google can take **5-10 minutes** to propagate the SHA-1 changes
- After adding SHA-1, wait a few minutes before testing
- Uninstall and reinstall the app if needed

### Step 5: Test Again

1. Stop the app completely
2. Uninstall from device/emulator
3. Rebuild and install:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
4. Try signing in again

## Alternative: Use Web Client ID (If Available)

If you have a Web Client ID from Google Cloud Console, you can add it to the code:

1. Get your Web Client ID from Google Cloud Console
2. Update `lib/services/auth_service.dart`:

```dart
GoogleSignIn get _googleSignIn {
  _googleSignInInstance ??= GoogleSignIn(
    // Add your Web Client ID here (optional but can help)
    // serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/fitness.activity.read',
      'https://www.googleapis.com/auth/fitness.heart_rate.read',
      'https://www.googleapis.com/auth/fitness.body.read',
    ],
  );
  return _googleSignInInstance!;
}
```

## Troubleshooting

### Still Getting Error?

1. **Double-check SHA-1**: Make sure you copied the correct SHA-1 (debug keystore for debug builds)
2. **Check Package Name**: Must match exactly in both places
3. **Wait Longer**: Google can take up to 10 minutes to propagate
4. **Check OAuth Consent Screen**: Make sure it's configured in Google Cloud Console
5. **Verify APIs Enabled**: 
   - Google Sign-In API
   - Google Fit API
   - Both should be enabled in Google Cloud Console

### For Release Builds

When building for release, you'll need to:
1. Get SHA-1 from your release keystore
2. Add that SHA-1 to Google Cloud Console as well

## Quick Command Reference

```bash
# Get SHA-1 (Gradle method)
cd frontend/android && ./gradlew signingReport

# Get SHA-1 (keytool method)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Clean and rebuild
cd frontend
flutter clean
flutter pub get
flutter run
```

