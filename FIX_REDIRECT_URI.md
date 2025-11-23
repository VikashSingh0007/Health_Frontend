# Fix redirect_uri_mismatch Error

## Problem
You're getting `Error 400: redirect_uri_mismatch` because Flutter web uses a dynamic port (like `localhost:53865`) and Google OAuth needs the redirect URI to be configured.

## Solution: Add Redirect URI to Google Cloud Console

### Step 1: Go to Google Cloud Console
1. Open [Google Cloud Console](https://console.cloud.google.com)
2. Select your project: `health-app`
3. Navigate to: **APIs & Services** → **Credentials**

### Step 2: Edit Web Application OAuth Client
1. Find your **Web Application** OAuth 2.0 Client ID
2. Click on it to edit

### Step 3: Add Authorized Redirect URIs
Under **Authorized redirect URIs**, add these (one per line):

```
http://localhost
http://localhost/
http://127.0.0.1
http://127.0.0.1/
```

**Important:** Use `http://localhost` (without port number) - this will work for any localhost port.

### Step 4: Save
1. Click **Save**
2. Wait 1-2 minutes for changes to propagate

### Step 5: Restart Flutter App
```bash
# Stop the current app (Ctrl+C)
# Then restart:
flutter run -d chrome
```

## Why This Works

Flutter web runs on dynamic ports (like `localhost:53865`, `localhost:53919`, etc.). By adding `http://localhost` (without port), Google OAuth will accept redirects from any localhost port.

## Alternative: Use Specific Port (Not Recommended)

If you want to use a specific port, you can:
1. Run Flutter with a fixed port: `flutter run -d chrome --web-port=8080`
2. Add `http://localhost:8080` to authorized redirect URIs

But using `http://localhost` is easier and more flexible.

## After Fixing

Once you've added the redirect URIs and restarted the app, Google Sign-In should work without the `redirect_uri_mismatch` error.

