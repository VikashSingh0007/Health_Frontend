# Web Setup for Flutter App

## Google Sign-In Web Configuration

For Flutter web, Google Sign-In requires the Client ID to be set in the HTML file.

### Steps:

1. **Get your Web Client ID from Google Cloud Console:**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Navigate to: **APIs & Services** → **Credentials**
   - Find your **Web Application** OAuth 2.0 Client ID
   - Copy the Client ID (it looks like: `123456789-abc...xyz.apps.googleusercontent.com`)

2. **Update `web/index.html`:**
   - Open `frontend/web/index.html`
   - Find this line:
     ```html
     <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
     ```
   - Replace `YOUR_WEB_CLIENT_ID.apps.googleusercontent.com` with your actual Client ID
   - Save the file

3. **Restart the app:**
   ```bash
   flutter run -d chrome
   ```

## Example:

If your Client ID is: `123456789-abcdefghijklmnop.apps.googleusercontent.com`

Then the meta tag should be:
```html
<meta name="google-signin-client_id" content="123456789-abcdefghijklmnop.apps.googleusercontent.com">
```

## Note:

- The Client ID should be the **Web Application** client ID (not Android/iOS)
- Make sure there are no extra spaces or characters
- The app must be restarted after changing the HTML file

