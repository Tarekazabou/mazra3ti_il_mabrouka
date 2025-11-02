# Voice Assistant Setup Guide 🎤

## Configuration Complete ✅

Your voice assistant is now configured with:

### LiveKit Configuration
- **Server**: `wss://mabroukas-assistant-ykypiir9.livekit.cloud`
- **API Key**: `APItDb5TvWMpVka`
- **API Secret**: Configured ✓
- **Room**: `farm-voice-assistant`

### Google Gemini AI
- **API Key**: Configured ✓
- **Model**: `gemini-2.0-flash` (optimized for voice interactions)

## Files Updated

1. **`lib/voice_chat_config.dart`**
   - Added LiveKit credentials
   - Added Gemini API key
   - Updated configuration validation
   - Added API key and secret fields

2. **`.env`** (created)
   - Contains all environment variables
   - Easier to manage credentials
   - Can be used with `flutter_dotenv` if needed

## How to Use the Voice Assistant

### 1. In the App
The voice assistant button should now be functional in your app.

```dart
// The configuration is now ready
VoiceChatConfig.isConfigured() // Returns true ✓
VoiceChatConfig.getConfigStatusMessage() // Returns "✅ الإعدادات جاهزة"
```

### 2. Testing the Voice Assistant

1. **Run your Flutter app:**
   ```bash
   flutter run -d edge
   ```

2. **Navigate to voice assistant screen:**
   - Look for the voice/microphone icon
   - Or navigate to the voice assistant from the menu

3. **Start talking:**
   - The assistant will use Gemini 2.0 Flash for responses
   - All responses will be in Arabic (العربية)
   - Focused on Tunisian agricultural advice

## Voice Assistant Features

The assistant is configured to help with:
- 🌱 Plant status and health information
- 💧 Irrigation advice and scheduling
- 🌾 Crop information and diseases
- 🌡️ Weather-based recommendations
- 📊 Farm management tips
- 🇹🇳 Tunisian climate-specific guidance

## System Instructions (Arabic)

The assistant follows these guidelines:
```
أنت مساعد زراعي ذكي متخصص في المزارع التونسية
- استخدم اللغة العربية فقط
- كن واضحاً ومباشراً
- استخدم لغة بسيطة يفهمها المزارعون
- قدم معلومات عملية ومفيدة
- ركز على الزراعة المستدامة والحفاظ على الماء
```

## Security Notes ⚠️

### Current Setup (Development)
- Credentials are hardcoded in the app
- ✅ Good for testing and development
- ❌ **NOT recommended for production**

### Production Recommendations
1. **Backend Token Generation:**
   ```python
   # Generate tokens on your backend
   from livekit import AccessToken
   
   token = AccessToken(api_key, api_secret)
   token.with_identity("farmer_mabrouka")
   token.with_name("Mabrouka")
   token.with_grants(AccessTokenGrants(
       room_join=True,
       room="farm-voice-assistant"
   ))
   ```

2. **Flutter App Requests Token:**
   ```dart
   // App requests token from your backend
   final token = await yourBackend.getLivekitToken(userId);
   ```

3. **Environment Variables:**
   - Move credentials to server-side
   - Never commit API secrets to git
   - Use `.env` files on server only

## LiveKit Dashboard

Access your LiveKit dashboard at:
https://cloud.livekit.io/

You can:
- Monitor active rooms
- See connected participants
- View usage statistics
- Generate new tokens
- Configure room settings

## Troubleshooting

### If voice doesn't work:

1. **Check Configuration:**
   ```dart
   print(VoiceChatConfig.isConfigured()); // Should be true
   print(VoiceChatConfig.getConfigStatusMessage()); // Should be "✅ الإعدادات جاهزة"
   ```

2. **Check LiveKit Connection:**
   - Verify URL is accessible
   - Check API key is valid
   - Ensure room name is correct

3. **Check Gemini API:**
   ```bash
   cd backend
   python test_gemini_api.py
   ```

4. **Browser Permissions:**
   - Allow microphone access
   - Check browser console for errors

5. **Network:**
   - Ensure WebSocket connections are allowed
   - Check firewall settings

## Testing Commands

### Test LiveKit Connection
```dart
// In your Flutter app
final room = Room();
try {
  await room.connect(
    VoiceChatConfig.livekitUrl,
    token, // Generate token first
  );
  print('✅ Connected to LiveKit');
} catch (e) {
  print('❌ Connection failed: $e');
}
```

### Test Gemini API
```bash
cd backend
python test_gemini_api.py
```

## Next Steps

1. ✅ Configuration is complete
2. 🎤 Test the voice assistant in your app
3. 🗣️ Try asking questions in Arabic
4. 📱 Test on different devices
5. 🚀 Deploy to production (with backend token generation)

## Example Conversation

**User (Arabic):** "ما حالة نباتات البندورة؟"  
**Assistant:** "نباتات البندورة بحالة جيدة. التربة رطبة بنسبة 50%. لا حاجة للري الآن. يُنصح بالانتظار حتى المساء."

**User:** "متى أسقي النباتات؟"  
**Assistant:** "الوقت المثالي للري هو في الصباح الباكر (6-8 صباحاً) أو في المساء (5-7 مساءً). تجنب الري في وقت الظهيرة لتقليل التبخر."

## Support

If you encounter issues:
1. Check the Flutter console for errors
2. Review LiveKit dashboard for connection logs
3. Verify API keys are correct
4. Check the backend logs

Your voice assistant is now ready to help Tunisian farmers! 🌱🎤🇹🇳
