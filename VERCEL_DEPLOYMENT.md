# Vercel Deployment Guide - Flutter Web App

## Prerequisites

1. **Vercel Account** - Sign up at [vercel.com](https://vercel.com)
2. **Flutter SDK** - Make sure Flutter is installed
3. **Backend Deployed** - Your backend should be deployed (e.g., on Render, Railway, etc.)
4. **GitHub Repository** - Code should be in a Git repository

## Step 1: Update Backend URL

Before deploying, update the production backend URL in `lib/utils/constants.dart`:

```dart
// Replace with your actual production backend URL
return 'https://your-backend-url.onrender.com';
```

## Step 2: Update Google OAuth Settings

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to **APIs & Services** → **Credentials**
3. Edit your **Web Application** OAuth 2.0 Client ID
4. Add your Vercel domain to **Authorized JavaScript origins**:
   - `https://your-app.vercel.app`
   - `https://your-custom-domain.com` (if using custom domain)
5. Add to **Authorized redirect URIs**:
   - `https://your-backend-url.onrender.com/auth/google/callback`

## Step 3: Deploy to Vercel

### Option A: Using Vercel CLI

1. **Install Vercel CLI:**
   ```bash
   npm i -g vercel
   ```

2. **Login to Vercel:**
   ```bash
   vercel login
   ```

3. **Navigate to frontend directory:**
   ```bash
   cd frontend
   ```

4. **Deploy:**
   ```bash
   vercel
   ```

5. **Follow the prompts:**
   - Set up and deploy? **Yes**
   - Which scope? **Your account**
   - Link to existing project? **No** (first time)
   - Project name? **health-tracker-frontend** (or your choice)
   - Directory? **./** (current directory)
   - Override settings? **No**

6. **For production deployment:**
   ```bash
   vercel --prod
   ```

### Option B: Using GitHub Integration

1. **Push code to GitHub:**
   ```bash
   git add .
   git commit -m "Prepare for Vercel deployment"
   git push origin main
   ```

2. **Go to Vercel Dashboard:**
   - Visit [vercel.com/new](https://vercel.com/new)
   - Click **Import Git Repository**
   - Select your repository
   - Click **Import**

3. **Configure Project:**
   - **Framework Preset:** Other
   - **Root Directory:** `frontend` (if deploying from root, leave empty)
   - **Build Command:** `bash build.sh` (or leave empty to use vercel.json)
   - **Output Directory:** `build/web`
   - **Install Command:** (leave empty, handled in build script)

4. **Environment Variables (if needed):**
   - Usually not needed for Flutter web, but if you have any, add them here

5. **Click Deploy**

## Step 4: Verify Deployment

1. After deployment, Vercel will provide you with a URL like:
   - `https://your-app.vercel.app`

2. **Test the app:**
   - Open the URL in browser
   - Try Google Sign-In
   - Verify backend connection

## Step 5: Custom Domain (Optional)

1. In Vercel dashboard, go to your project
2. Click **Settings** → **Domains**
3. Add your custom domain
4. Follow DNS configuration instructions

## Important Notes

### Build Configuration

The `vercel.json` file is already configured with:
- Build command: `flutter build web --release`
- Output directory: `build/web`
- SPA routing support (all routes redirect to index.html)
- Cache headers for assets

### Backend CORS

Make sure your backend allows requests from your Vercel domain:

```typescript
// In your NestJS backend (main.ts)
app.enableCors({
  origin: [
    'https://your-app.vercel.app',
    'https://your-custom-domain.com',
  ],
  credentials: true,
});
```

### Environment Detection

The app automatically detects if it's running on Vercel:
- If URL contains `vercel.app` → Uses production backend URL
- Otherwise → Uses localhost (for development)

## Troubleshooting

### Build Fails - "flutter: command not found"

This means Flutter is not installed on Vercel. The `build.sh` script will automatically install Flutter, but if it still fails:

1. **Check build.sh is executable:**
   ```bash
   chmod +x build.sh
   git add build.sh
   git commit -m "Make build.sh executable"
   git push
   ```

2. **Verify build script:**
   - Make sure `build.sh` is in the root of your frontend directory
   - Check that it has execute permissions

3. **Alternative: Use Vercel Build Settings:**
   - In Vercel dashboard → Project Settings → Build & Development Settings
   - Override Build Command: `bash build.sh`
   - Override Output Directory: `build/web`

### Build Timeout

If build times out (usually > 5 minutes):
1. Flutter installation takes time - first build will be slower
2. Subsequent builds will be faster (cached)
3. Consider using a faster Flutter installation method

### Build Fails - Other Issues

1. **Check Flutter version:**
   ```bash
   flutter --version
   ```

2. **Clean build:**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Test build locally:**
   ```bash
   flutter build web --release
   ```

### OAuth Not Working

1. Verify Google Cloud Console settings
2. Check redirect URIs match exactly
3. Ensure backend callback URL is correct

### Backend Connection Issues

1. Verify backend is deployed and running
2. Check CORS settings in backend
3. Update `baseUrl` in `constants.dart` if needed

## File Structure

```
frontend/
├── vercel.json          # Vercel configuration
├── .vercelignore        # Files to ignore during deployment
├── lib/
│   └── utils/
│       └── constants.dart  # Backend URL configuration
└── build/
    └── web/             # Build output (generated)
```

## Quick Deploy Commands

```bash
# First time setup
cd frontend
vercel login
vercel

# Production deployment
vercel --prod

# View deployments
vercel ls

# View logs
vercel logs
```

## Support

If you face any issues:
1. Check Vercel build logs
2. Verify Flutter build works locally
3. Check backend is accessible
4. Verify Google OAuth settings

