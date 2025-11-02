# Quick Start Guide - Voice Chat Setup

This guide will help you quickly set up the voice chat feature with your LiveKit and Gemini credentials.

## ⚠️ IMPORTANT SECURITY NOTE

**Your API keys and secrets should NEVER be committed to Git or shared publicly!**

If you've shared your credentials in a public place (like a GitHub comment), you should:
1. **Immediately revoke/regenerate them** from the respective services
2. Follow the secure setup below

## Prerequisites

Make sure you have Python 3 installed (for generating LiveKit tokens).

## Step 1: Install LiveKit Python Package

```bash
pip install livekit
```

## Step 2: Set Up Environment Variables

Create a file called `.env.local` in the `my_app` directory (this file is already in .gitignore):

```bash
# LiveKit Configuration
LIVEKIT_URL=wss://mabroukas-assistant-ykypiir9.livekit.cloud
LIVEKIT_API_KEY=APItDb5TvWMpVka
LIVEKIT_API_SECRET=TgdPbPhF20GB6s3DG1HafOPXMriI5WQ4FQh24UjaOoI

# Gemini API Configuration
GEMINI_API_KEY=AIzaSyCVrl6QD5zJOm8ZBFuxqgMueTlRlQRMbsw
```

**Note**: The `.env.local` file will NOT be committed to Git (it's in .gitignore).

## Step 3: Load Environment Variables

### On Linux/Mac:

```bash
export LIVEKIT_URL=wss://mabroukas-assistant-ykypiir9.livekit.cloud
export LIVEKIT_API_KEY=APItDb5TvWMpVka
export LIVEKIT_API_SECRET=TgdPbPhF20GB6s3DG1HafOPXMriI5WQ4FQh24UjaOoI
export GEMINI_API_KEY=AIzaSyCVrl6QD5zJOm8ZBFuxqgMueTlRlQRMbsw
```

### On Windows CMD:

```cmd
set LIVEKIT_URL=wss://mabroukas-assistant-ykypiir9.livekit.cloud
set LIVEKIT_API_KEY=APItDb5TvWMpVka
set LIVEKIT_API_SECRET=TgdPbPhF20GB6s3DG1HafOPXMriI5WQ4FQh24UjaOoI
set GEMINI_API_KEY=AIzaSyCVrl6QD5zJOm8ZBFuxqgMueTlRlQRMbsw
```

### On Windows PowerShell:

```powershell
$env:LIVEKIT_URL="wss://mabroukas-assistant-ykypiir9.livekit.cloud"
$env:LIVEKIT_API_KEY="APItDb5TvWMpVka"
$env:LIVEKIT_API_SECRET="TgdPbPhF20GB6s3DG1HafOPXMriI5WQ4FQh24UjaOoI"
$env:GEMINI_API_KEY="AIzaSyCVrl6QD5zJOm8ZBFuxqgMueTlRlQRMbsw"
```

## Step 4: Generate LiveKit Token

Run the token generator script:

```bash
cd my_app
python generate_livekit_token.py
```

The script will:
1. Read your API key and secret from environment variables
2. Prompt you for token parameters (or use defaults)
3. Generate a token valid for 24 hours
4. Display the token and instructions

**Example output:**

```
✅ Token generated successfully!
Your LiveKit Token:
----------------------------------------------------------------------
eyJhbGc...very-long-token-string...
----------------------------------------------------------------------
```

Copy this token - you'll need it in the next step.

## Step 5: Run the Flutter App

With the generated token, run:

```bash
flutter run \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
  --dart-define=LIVEKIT_URL=$LIVEKIT_URL \
  --dart-define=LIVEKIT_TOKEN='your-generated-token-here'
```

Replace `'your-generated-token-here'` with the token from Step 4.

**Full example:**

```bash
flutter run \
  --dart-define=GEMINI_API_KEY=AIzaSyCVrl6QD5zJOm8ZBFuxqgMueTlRlQRMbsw \
  --dart-define=LIVEKIT_URL=wss://mabroukas-assistant-ykypiir9.livekit.cloud \
  --dart-define=LIVEKIT_TOKEN='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

## Step 6: Test the Voice Chat

1. Open the app
2. Navigate to the vegetation display screen
3. Scroll down to the "محادثة صوتية بالعربية" section
4. Tap "بدء المحادثة الصوتية"
5. Grant microphone permission when prompted
6. Wait for "متصل" status
7. Tap the test button (💬) to try a demo conversation

## Troubleshooting

### "يرجى تكوين: Gemini API Key"

**Problem**: Environment variables not passed to Flutter.

**Solution**: Make sure you're using `--dart-define` flags when running the app.

### "فشل الاتصال: Connection failed"

**Problem**: Token expired or invalid.

**Solution**: 
1. Generate a new token using `generate_livekit_token.py`
2. Make sure the LIVEKIT_URL matches your server
3. Check your internet connection

### Token expires too quickly

**Problem**: Token valid for only 24 hours by default.

**Solution**: Generate token with longer validity:
```bash
python generate_livekit_token.py
# When prompted, enter a larger number of hours (e.g., 168 for 1 week)
```

### Permission denied error

**Problem**: App can't access microphone.

**Solution**:
1. Go to device Settings → Apps → Your App → Permissions
2. Enable Microphone permission
3. Restart the app

## Building for Release

For release builds, use the same approach:

```bash
flutter build apk \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
  --dart-define=LIVEKIT_URL=$LIVEKIT_URL \
  --dart-define=LIVEKIT_TOKEN='your-token'
```

## Production Setup (Recommended)

For production, you should:

1. **Create a backend API** that generates tokens on-demand
2. **Never hardcode tokens** in the app
3. **Use short-lived tokens** (1-2 hours max)
4. **Implement user authentication** before issuing tokens
5. **Rotate API keys** regularly

See `VOICE_CHAT_SETUP.md` for detailed production setup instructions.

## Security Checklist

- [ ] API keys stored in environment variables (not in code)
- [ ] `.env.local` file in .gitignore
- [ ] Tokens generated fresh for each session
- [ ] Old tokens revoked after use
- [ ] Credentials not shared publicly
- [ ] Production uses backend token generation

## Need Help?

If you encounter issues:
1. Check the main `VOICE_CHAT_SETUP.md` documentation
2. Review the `VOICE_CHAT_README_AR.md` user guide
3. Check Flutter logs: `flutter logs`
4. Verify all environment variables are set correctly

## Example: Complete Setup Script

Save this as `setup_and_run.sh`:

```bash
#!/bin/bash

# Set environment variables
export LIVEKIT_URL=wss://mabroukas-assistant-ykypiir9.livekit.cloud
export LIVEKIT_API_KEY=APItDb5TvWMpVka
export LIVEKIT_API_SECRET=TgdPbPhF20GB6s3DG1HafOPXMriI5WQ4FQh24UjaOoI
export GEMINI_API_KEY=AIzaSyCVrl6QD5zJOm8ZBFuxqgMueTlRlQRMbsw

# Generate token
echo "Generating LiveKit token..."
cd my_app
TOKEN=$(python -c "
from livekit import api
from datetime import timedelta
import os
token = api.AccessToken(os.getenv('LIVEKIT_API_KEY'), os.getenv('LIVEKIT_API_SECRET'))
token.with_identity('farmer-user').with_name('Farmer')
token.with_grants(api.VideoGrants(room_join=True, room='farm-voice-assistant'))
token.with_ttl(timedelta(hours=24))
print(token.to_jwt())
")

echo "Token generated!"
echo ""

# Run Flutter app
echo "Starting Flutter app..."
flutter run \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY \
  --dart-define=LIVEKIT_URL=$LIVEKIT_URL \
  --dart-define=LIVEKIT_TOKEN="$TOKEN"
```

Make it executable and run:
```bash
chmod +x setup_and_run.sh
./setup_and_run.sh
```

---

**You're all set! The voice chat feature should now work with your credentials.** 🎤✅
