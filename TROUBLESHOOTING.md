# CommunityRun - Troubleshooting Guide

## Current Issue: Plugin Registration Error

The error you're experiencing is due to missing Java/Android toolchain setup in WSL environment.

## Quick Fix Options

### Option 1: Use Windows Command Prompt (Recommended)

1. **Open Windows Command Prompt** (not WSL)
2. **Navigate to project directory:**
   ```cmd
   cd C:\Users\paninfra\Desktop\CaludeAI\ComunityRun_dev\ComunityRun
   ```
3. **Run the debug script:**
   ```cmd
   run_debug.bat
   ```

### Option 2: Fix WSL Environment

If you prefer to use WSL, you need to:

1. **Install Java/JDK in WSL:**
   ```bash
   sudo apt update
   sudo apt install openjdk-11-jdk
   export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
   ```

2. **Fix Android SDK path:**
   ```bash
   export ANDROID_SDK_ROOT=/mnt/c/Users/paninfra/AppData/Local/Android/Sdk
   export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools
   ```

3. **Add to ~/.bashrc for persistence:**
   ```bash
   echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc
   echo 'export ANDROID_SDK_ROOT=/mnt/c/Users/paninfra/AppData/Local/Android/Sdk' >> ~/.bashrc
   echo 'export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools' >> ~/.bashrc
   source ~/.bashrc
   ```

## Expected Debug Output After Fix

Once the app runs successfully, you should see the detailed Strava debug logs we added:

```
🔍 [STRAVA DEBUG HELPER] ===== CONFIGURATION STATUS =====
🔵 [STRAVA CONFIG] Configuration check:
🔵 [STRAVA CONFIG] Overall configured: true
✅ [STRAVA DEBUG HELPER] Configuration looks good!

🔵 [STRAVA DEBUG] Starting launchStravaAuth
🔵 [STRAVA DEBUG] Method 1: Trying external application launch...
✅ [STRAVA DEBUG] Method 1 SUCCESS: External application launch worked
```

## Strava Authentication Testing Steps

Once the app launches:

1. **Test Configuration:**
   - Look for `🔵 [STRAVA CONFIG] Overall configured: true`
   - If false, update credentials in `lib/constants/strava_config.dart`

2. **Test URL Launching:**
   - Tap "Continue with Strava" button
   - Should see launch method debug logs
   - Browser/Strava app should open

3. **Test Token Exchange:**
   - After authorizing in Strava, copy the authorization code
   - Paste it in the app
   - Look for token exchange debug logs

4. **Debug Output Examples:**

   **Success Case:**
   ```
   ✅ [STRAVA DEBUG] Step 1 SUCCESS: Token exchange completed
   ✅ [STRAVA DEBUG] Step 2 SUCCESS: Got Strava profile  
   ✅ [STRAVA DEBUG] Step 3 SUCCESS: Firebase user created/updated
   ✅ [STRAVA DEBUG] ALL STEPS COMPLETED: Authentication successful!
   ```

   **Failure Cases:**
   ```
   ❌ [STRAVA DEBUG] Step 1 FAILED: Token exchange returned null
   ❌ [STRAVA DEBUG] Token exchange failed with status: 400
   ❌ [STRAVA DEBUG] Error response body: {"error":"invalid_grant"}
   ```

## Common Issues & Solutions

### 1. "Cannot launch URL"
- **Cause:** Missing AndroidManifest.xml configuration
- **Solution:** Already fixed in recent updates

### 2. "Token exchange failed with status: 400"  
- **Cause:** Invalid Strava credentials or authorization code
- **Solution:** Check client ID/secret in StravaConfig

### 3. "Invalid authorization code"
- **Cause:** Code expired, malformed, or used twice
- **Solution:** Get fresh code from Strava authorization

### 4. "Firebase anonymous sign-in failed"
- **Cause:** Firebase not initialized
- **Solution:** Check Firebase configuration

## Environment Requirements

- **Windows:** Flutter, Android Studio, Java JDK
- **WSL:** Java JDK, Android SDK access
- **Device:** Android emulator or physical device
- **Network:** Internet connection for Strava API

## Support

The comprehensive debug logging will help identify exactly where the authentication fails. Share the debug output for specific troubleshooting assistance.