# Fix redirect_uri_mismatch Error

## Problem
You're getting `Error 400: redirect_uri_mismatch` because the redirect URI used by Flutter web doesn't match what's configured in Google Cloud Console.

## Solution

### Step 1: Find Your Current Redirect URI

Flutter web is running on: `http://localhost:53865` (or similar port)

The redirect URI format for Google Sign-In web is: `http://localhost:PORT` or `http://localhost`

### Step 2: Add Redirect URI to Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to: **APIs & Services** → **Credentials**
3. Click on your **Web Application** OAuth 2.0 Client ID
4. Under **Authorized redirect URIs**, add:
   - `http://localhost` (for any localhost port)
   - OR `http://localhost:53865` (for specific port - but port changes each run)
   - OR `http://127.0.0.1` (alternative)

### Step 3: Recommended Solution (Use localhost without port)

Add these redirect URIs:
```
http://localhost
http://localhost/
http://127.0.0.1
http://127.0.0.1/
```

This will work for any localhost port.

### Step 4: Save and Wait

- Click **Save** in Google Cloud Console
- Wait 1-2 minutes for changes to propagate
- Restart your Flutter app

### Step 5: Alternative - Use Backend OAuth Flow for Web

If the above doesn't work, we can modify the app to use the backend OAuth flow for web instead of direct Google Sign-In.

## Quick Fix

The easiest solution is to add `http://localhost` (without port) to your authorized redirect URIs in Google Cloud Console. This will work for any localhost port.

