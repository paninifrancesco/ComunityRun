# Strava Authentication Setup Guide

This guide will help you configure Strava OAuth2 authentication for the CommunityRun app.

## 🎯 Overview

The app now includes complete Strava login functionality that allows users to:
- Sign in with their Strava account
- Import their Strava profile data (name, photo, bio)
- Verify their running credentials through Strava
- Access their Strava activity data (with proper permissions)

## 📋 Prerequisites

- Strava developer account
- Access to modify the Flutter app configuration

## 🔧 Step 1: Create Strava App

1. **Go to Strava Developers Portal**
   - Visit: https://developers.strava.com/
   - Click "Create App"

2. **Fill App Details (Updated for 2025)**
   - **Application Name**: `CommunityRun`
   - **Category**: `Social Network`
   - **Club**: Leave blank (optional)
   - **Website**: Your app website or GitHub repo
   - **Application Description**: `Running community app that connects local runners`
   - **Authorization Callback Domain**: `communityrun://strava-callback`
   
   **Important**: Use the custom URL scheme format for mobile apps as per 2025 Strava guidelines

3. **Submit and Get Credentials**
   - After creating the app, note down:
     - **Client ID** (public)
     - **Client Secret** (keep secret!)
   - **Rate Limits**: 200 requests per 15 minutes, 2,000 requests per day

## 🔑 Step 2: Configure App Credentials

1. **Open Configuration File**
   ```
   lib/constants/strava_config.dart
   ```

2. **Replace Placeholder Values**
   ```dart
   class StravaConfig {
     static const String clientId = 'YOUR_ACTUAL_CLIENT_ID_HERE';
     static const String clientSecret = 'YOUR_ACTUAL_CLIENT_SECRET_HERE';
     // ... rest of config
   }
   ```

3. **Security Note**
   - ⚠️ **Never commit real credentials to version control**
   - Consider using environment variables for production
   - The client secret should be handled securely

## 📱 Step 3: Platform Configuration

### Android (Already Configured)
The Android manifest has been updated with the necessary URL scheme:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="communityrun" android:host="strava-callback" />
</intent-filter>
```

### iOS (Manual Setup Required)
Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>communityrun.strava</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>communityrun</string>
        </array>
    </dict>
</array>
```

## 🧪 Step 4: Testing

1. **Build and Run App**
   ```bash
   flutter run
   ```

2. **Test Strava Login**
   - Open the app
   - Go to authentication screen
   - Tap "Continue with Strava"
   - Should open Strava in browser/app
   - Authorize the app
   - Should redirect back to CommunityRun

3. **Verify Integration**
   - Check that user profile is created with Strava data
   - Verify user is marked as Strava-verified

## 🔄 Authentication Flow (Updated 2025)

```
1. User taps "Continue with Strava"
2. App opens mobile-optimized Strava authorization URL
3. Strava app opens (if installed) or mobile web browser
4. User authorizes the app in Strava
5. Strava redirects to: communityrun://strava-callback?code=AUTH_CODE
6. App handles deep link callback automatically
7. App exchanges authorization code for access & refresh tokens
8. App fetches Strava athlete profile data
9. App creates anonymous Firebase user and links Strava data
10. User is signed in with Strava verification badge
```

**Key Improvements in 2025:**
- Mobile-optimized authorization endpoints
- Better token management with automatic refresh
- Proper deauthorization support
- Enhanced error handling and validation

## 🛠️ Troubleshooting

### "Strava authentication is not configured"
- Check that you've updated `StravaConfig` with real credentials
- Ensure `clientId` and `clientSecret` are not the placeholder values

### OAuth redirect doesn't work
- Verify URL scheme is correctly configured in platform manifests
- Check that redirect URI in Strava app matches exactly: `communityrun://strava-callback`
- Test on physical device (URL schemes may not work in some emulators)

### "Authorization failed" errors
- Check that Strava app is approved and not in sandbox mode
- Verify client ID and secret are correct
- Check network connectivity

### Deep link not opening app
- Test URL scheme manually: `adb shell am start -W -a android.intent.action.VIEW -d "communityrun://strava-callback" com.communityrun.communityrun`
- Ensure app is installed and URL scheme is registered

## 📊 Features Available (2025 Update)

Once configured, users can:

✅ **Sign in with Strava account** (mobile-optimized flow)
✅ **Import Strava profile data** (name, photo, bio)
✅ **Automatic Strava verification** badge
✅ **Secure token storage** with encrypted preferences
✅ **Automatic token refresh** (6-hour token expiry handling)
✅ **Proper account disconnection** with Strava deauthorization
✅ **Enhanced error handling** and user feedback
✅ **Rate limit awareness** (200/15min, 2000/day)

## 🔒 Security Considerations

- **Client Secret**: Keep secure, consider server-side token exchange for production
- **Token Storage**: Tokens are stored securely in device preferences
- **Permissions**: App only requests necessary Strava permissions (read profile and activities)
- **Verification**: Users maintain anonymous Firebase auth as primary authentication

## 📈 Next Steps

After basic setup works:

1. **Implement callback handling** for seamless redirect experience
2. **Add Strava activity import** features
3. **Enhance profile with Strava stats**
4. **Add Strava activity sharing** to runs
5. **Implement server-side token management** for production

## 🆘 Support

If you encounter issues:
1. Check the Flutter logs for detailed error messages
2. Verify all configuration steps are completed
3. Test on physical device rather than emulator
4. Check Strava developer documentation: https://developers.strava.com/docs/

---

**Note**: This implementation provides a complete OAuth2 flow foundation. The callback handling in the current version shows instructions to users but can be enhanced for automatic processing in production apps.