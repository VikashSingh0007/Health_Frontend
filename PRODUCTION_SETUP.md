# Production Setup Checklist

Your app is now deployed at: **https://health-frontend-beta.vercel.app/**

## ✅ Step 1: Update Backend URL (DONE)

The constants.dart file is already configured to use production backend URL for web.

## 🔧 Step 2: Update Google OAuth Settings (REQUIRED)

1. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com
   - Select your project

2. **Navigate to Credentials:**
   - Go to: **APIs & Services** → **Credentials**
   - Find your **Web Application** OAuth 2.0 Client ID
   - Click to edit

3. **Add Authorized JavaScript origins:**
   ```
   https://health-frontend-beta.vercel.app
   ```

4. **Verify Authorized redirect URIs:**
   - Should have: `https://health-xe8h.onrender.com/auth/google/callback`
   - (This is your backend callback URL)

5. **Save changes**

## 🔧 Step 3: Update Backend CORS Settings

Make sure your backend allows requests from Vercel domain:

**In your backend (health-backend/src/main.ts):**

```typescript
app.enableCors({
  origin: [
    'https://health-frontend-beta.vercel.app',
    'http://localhost:3000', // For local development
  ],
  credentials: true,
});
```

## 🧪 Step 4: Test the App

1. **Open the app:**
   - Visit: https://health-frontend-beta.vercel.app/

2. **Test Google Sign-In:**
   - Click "Sign in with Google"
   - Should redirect to Google login
   - After login, should redirect back to app

3. **Check Console for Errors:**
   - Open browser DevTools (F12)
   - Check Console tab for any errors
   - Check Network tab for API calls

## 🐛 Common Issues & Fixes

### Issue: "CORS error" or "Network error"

**Solution:**
- Check backend CORS settings (Step 3)
- Verify backend is running and accessible
- Check backend URL in constants.dart matches your actual backend

### Issue: "redirect_uri_mismatch"

**Solution:**
- Verify Google OAuth settings (Step 2)
- Check redirect URI in Google Cloud Console matches exactly
- Wait 1-2 minutes after updating (Google needs time to propagate)

### Issue: "Backend connection failed"

**Solution:**
- Verify backend URL: `https://health-xe8h.onrender.com`
- Check if backend is running
- Test backend directly: `curl https://health-xe8h.onrender.com/auth/profile`

## 📝 Quick Reference

- **Frontend URL:** https://health-frontend-beta.vercel.app/
- **Backend URL:** https://health-xe8h.onrender.com
- **Google OAuth:** https://console.cloud.google.com

## ✅ Next Steps

1. ✅ Update Google OAuth settings (Step 2)
2. ✅ Update backend CORS (Step 3)
3. ✅ Test the app (Step 4)
4. ✅ Share the URL with users!

## 🎉 You're Done!

Once all steps are complete, your app will be fully functional in production!

