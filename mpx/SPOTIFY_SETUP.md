# Spotify API Setup

To connect this app to the Spotify API, you need to:

## 1. Create a Spotify App

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Log in with your Spotify account
3. Click **"Create App"**
4. Fill in the app details:
   - **App name**: MP-X (or any name you prefer)
   - **App description**: Mood-based music playlist generator
   - **Redirect URI**: `http://127.0.0.1:8080/callback` ⚠️ **IMPORTANT: Copy this exactly!**
   - **Website**: (optional, can leave blank)
   - Accept the terms and click **"Save"**

## 2. Get Your Credentials

1. After creating the app, you'll be on the app dashboard
2. You'll see:
   - **Client ID** - Copy this (it's visible immediately)
   - **Client Secret** - Click **"View client secret"** or **"Show client secret"** to reveal it, then copy it

⚠️ **Important**: The Client Secret is only shown once! Save it somewhere safe.

## 3. Update the Code

1. Open `lib/services/spotify_service.dart` in your project
2. Find these lines (around line 9-10):

```dart
static const String clientId = 'YOUR_SPOTIFY_CLIENT_ID';
static const String clientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
```

3. Replace with your actual credentials:

```dart
static const String clientId = 'your_actual_client_id_here';
static const String clientSecret = 'your_actual_client_secret_here';
```

**Example:**
```dart
static const String clientId = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
static const String clientSecret = 'A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6';
```

4. **Save the file**
5. **Restart your app** (hot reload won't pick up constant changes)

## Troubleshooting "INVALID_CLIENT" Error

If you see "INVALID_CLIENT: Invalid client" error:

1. ✅ **Check your Client ID** - Make sure you copied it correctly (no extra spaces)
2. ✅ **Check your Client Secret** - Make sure you copied it correctly (no extra spaces)
3. ✅ **Verify Redirect URI** - In your Spotify Dashboard, make sure the Redirect URI is exactly: `http://127.0.0.1:8080/callback`
4. ✅ **Restart the app** - After changing credentials, fully restart the app (not just hot reload)
5. ✅ **Check for typos** - Make sure there are no quotes or spaces around your credentials

## 4. Install Dependencies

Run:
```bash
flutter pub get
```

## 5. Run the App

```bash
flutter run
```

## How It Works

1. When you click a "MOOD-BALANCING PLAYLIST" button, the app will:
   - Check if you're authenticated with Spotify
   - If not, it will open a browser for you to log in and authorize the app
   - Once authorized, it will search for tracks matching the mood
   - Create a playlist in your Spotify account
   - Provide a link to open the playlist

## Note

The redirect URI `http://127.0.0.1:8080/callback` is used for the OAuth flow. For production, you may want to set up a proper callback handler or use a deep link scheme.

**Note**: `127.0.0.1` and `localhost` are treated as different URIs by Spotify. Make sure the redirect URI in your code matches EXACTLY what you configure in the Spotify Dashboard.

