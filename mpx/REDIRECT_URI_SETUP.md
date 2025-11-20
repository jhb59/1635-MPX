# Redirect URI Setup Guide

## Spotify Requirements

According to Spotify's security requirements:
- ✅ Use `http://127.0.0.1:PORT` (NOT `localhost`)
- ✅ Must match EXACTLY between code and Spotify Dashboard
- ✅ HTTP is allowed for loopback addresses (127.0.0.1)

## Step-by-Step Setup

### 1. Find Your Flutter Web Port

When you run `flutter run -d chrome`, look at the terminal output. You'll see something like:

```
Flutter run key commands.
Running on http://localhost:54321
```

**Note the port number** (in this example, it's `54321`).

### 2. Update the Code

Open `lib/services/spotify_service.dart` and find line 15:

```dart
static const String redirectUri = 'http://127.0.0.1:8080/callback';
```

Replace `8080` with your actual port. For example, if your port is `54321`:

```dart
static const String redirectUri = 'http://127.0.0.1:54321/callback';
```

### 3. Update Spotify Dashboard

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Click on your app (MPX)
3. Click "Edit Settings"
4. Under "Redirect URIs", update to match your code:
   - Remove: `http://127.0.0.1:8080/callback`
   - Add: `http://127.0.0.1:YOUR_PORT/callback` (replace YOUR_PORT with your actual port)
5. Click "Add" and then "Save"

### 4. Restart Your App

After making changes, fully restart your Flutter app (not just hot reload).

## Alternative: Use Manual Code Entry

If you prefer not to update the redirect URI, you can use the manual code entry feature:

1. Click "Continue with Spotify"
2. Authorize in the browser
3. When redirected to the error page, copy the `code` parameter from the URL
4. Click "Enter Authorization Code Manually" in the app
5. Paste the code and click "Submit Code"

This works regardless of the redirect URI port.

## Troubleshooting

**Error: "INVALID_CLIENT: Invalid redirect URI"**
- ✅ Check that the port in your code matches the port in Spotify Dashboard
- ✅ Make sure you're using `127.0.0.1` (NOT `localhost`)
- ✅ Make sure there are no extra spaces or typos
- ✅ Restart the app after making changes

**Port keeps changing?**
- Flutter web assigns a random port each time
- You can either:
  1. Update both code and Spotify Dashboard each time (add multiple redirect URIs in Spotify)
  2. Use the manual code entry method (recommended for development)

