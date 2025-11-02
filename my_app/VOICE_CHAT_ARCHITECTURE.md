# Voice Chat Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter Mobile App                           │
│                  (Vegetation Display Widget)                     │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    User Interface (Arabic)                │  │
│  │                                                            │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │  │
│  │  │  Veg     │  │  Voice   │  │ Status   │  │ Response│ │  │
│  │  │  Cards   │  │  Button  │  │ Display  │  │  Area   │ │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │  │
│  │                                                            │  │
│  │     النباتات المزروعة   |   بدء المحادثة   |   متصل      │  │
│  └──────────────────┬─────────────────────────────────────┬─┘  │
│                     │                                     │     │
│  ┌──────────────────▼──────────┐     ┌──────────────────▼──┐  │
│  │   LiveKit Client            │     │  Gemini AI Client   │  │
│  │   (livekit_client)          │     │  (generative_ai)    │  │
│  │                              │     │                     │  │
│  │  - Room management          │     │  - Chat session     │  │
│  │  - Audio tracks             │     │  - Farm context     │  │
│  │  - Permissions              │     │  - Arabic prompts   │  │
│  └──────────────┬───────────────┘     └──────────┬──────────┘  │
│                 │                                │              │
└─────────────────┼────────────────────────────────┼──────────────┘
                  │                                │
                  │                                │
          ┌───────▼──────────┐            ┌────────▼─────────┐
          │  LiveKit Server  │            │  Gemini API      │
          │                  │            │  (Google Cloud)  │
          │  - WebRTC        │            │                  │
          │  - Audio relay   │            │  - gemini-2.0    │
          │  - Room mgmt     │            │    -flash        │
          └──────────────────┘            │  - Arabic NLP    │
                                          └──────────────────┘
```

## Data Flow

### 1. Voice Chat Initialization

```
User Action: Tap "بدء المحادثة الصوتية"
     │
     ├─→ Request microphone permission
     │   └─→ Permission.microphone.request()
     │
     ├─→ Initialize Gemini AI
     │   ├─→ Load API key from config
     │   ├─→ Create GenerativeModel
     │   └─→ Start chat session with Arabic system prompt
     │
     └─→ Connect to LiveKit
         ├─→ Create Room instance
         ├─→ Connect to server (URL + Token)
         ├─→ Enable microphone
         └─→ Setup event listeners
```

### 2. Voice Conversation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: User Speaks                                              │
│ ┌─────────┐                                                      │
│ │ 🎤 User │ "ما هي النباتات في مزرعتي؟"                        │
│ └────┬────┘                                                      │
│      │                                                           │
│      │ Audio Input                                               │
│      ▼                                                           │
│ ┌────────────────┐                                               │
│ │ LiveKit Client │ Capture audio from microphone                │
│ └────────┬───────┘                                               │
│          │                                                       │
│          │ Audio Stream (WebRTC)                                 │
│          ▼                                                       │
│ ┌────────────────┐                                               │
│ │ LiveKit Server │ Receive and process audio                    │
│ └────────────────┘                                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Speech to Text (TODO)                                    │
│ ┌──────────────────────┐                                         │
│ │ Speech-to-Text API   │ Convert Arabic audio to text           │
│ │ (Google Cloud)       │ Output: "ما هي النباتات في مزرعتي؟"   │
│ └──────────┬───────────┘                                         │
│            │ Text Query                                          │
└────────────┼─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Step 3: AI Processing                                            │
│            │                                                     │
│            ▼                                                     │
│ ┌──────────────────┐                                             │
│ │ Farm Model       │ Gather current farm data:                  │
│ │ (Provider)       │ - النباتات: طماطم، خيار، فلفل              │
│ └────────┬─────────┘ - عدد النباتات: 3                          │
│          │           - حالة المضخة: تعمل                         │
│          │           - رطوبة التربة: 65%                         │
│          │                                                       │
│          │ Farm Context                                          │
│          ▼                                                       │
│ ┌──────────────────┐                                             │
│ │ Gemini AI        │ Process with context:                      │
│ │ gemini-2.0-flash │                                             │
│ │                  │ Query: "ما هي النباتات في مزرعتي؟"        │
│ │ System Prompt:   │ Context: { vegetation, pump, sensors }     │
│ │ "أنت مساعد       │                                             │
│ │  زراعي..."      │ Response: "في مزرعتك ثلاثة أنواع من        │
│ └────────┬─────────┘           النباتات: الطماطم والخيار        │
│          │                      والفلفل..."                      │
└──────────┼─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Step 4: Text to Speech (TODO)                                    │
│          │                                                       │
│          │ Text Response                                         │
│          ▼                                                       │
│ ┌──────────────────────┐                                         │
│ │ Text-to-Speech API   │ Convert Arabic text to audio           │
│ │ (Google Cloud)       │                                         │
│ └──────────┬───────────┘                                         │
│            │ Audio Output                                        │
└────────────┼─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Step 5: Play Response                                            │
│            │                                                     │
│            ▼                                                     │
│ ┌────────────────┐                                               │
│ │ LiveKit Client │ Stream audio response                        │
│ └────────┬───────┘                                               │
│          │                                                       │
│          │ Audio Playback                                        │
│          ▼                                                       │
│ ┌─────────────┐                                                  │
│ │ 🔊 Speaker  │ "في مزرعتك ثلاثة أنواع من النباتات..."          │
│ └─────────────┘                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### VegetationDisplayWidget State

```dart
State {
  // LiveKit components
  Room? _room                    // WebRTC room for audio
  bool _isConnected              // Connection status
  bool _isListening              // Currently listening
  
  // Gemini AI components
  GenerativeModel? _geminiModel  // AI model instance
  ChatSession? _chatSession      // Conversation session
  List<Map> _conversationHistory // Message history
  
  // UI state
  String _statusMessage          // Current status (Arabic)
  String _lastResponse           // Last AI response (Arabic)
  bool _isSpeaking              // Currently speaking
}
```

### Configuration System

```dart
VoiceChatConfig {
  // Environment-based configuration
  GEMINI_API_KEY      // From env or .env
  LIVEKIT_URL         // WebSocket URL
  LIVEKIT_TOKEN       // Access token
  LIVEKIT_ROOM        // Room name
  
  // Validation
  isConfigured()              // Check if all keys present
  getConfigStatusMessage()    // Status in Arabic
  
  // System prompts
  geminiSystemInstruction     // Arabic agricultural assistant
}
```

## Permission Flow

### Android

```
App Launch
    │
    ├─→ Manifest declares permissions
    │   ├─ INTERNET
    │   ├─ RECORD_AUDIO
    │   ├─ MODIFY_AUDIO_SETTINGS
    │   └─ ACCESS_NETWORK_STATE
    │
User taps voice button
    │
    └─→ Runtime permission request
        ├─ permission_handler package
        ├─ Shows system dialog
        └─→ User grants/denies
            │
            ├─ Granted → Connect to LiveKit
            └─ Denied → Show error message (Arabic)
```

### iOS

```
App Launch
    │
    ├─→ Info.plist declares permissions
    │   ├─ NSMicrophoneUsageDescription (Arabic)
    │   ├─ NSCameraUsageDescription (Arabic)
    │   └─ NSLocalNetworkUsageDescription (Arabic)
    │
User taps voice button
    │
    └─→ Runtime permission request
        ├─ permission_handler package
        ├─ Shows system dialog with Arabic text
        └─→ User grants/denies
            │
            ├─ Granted → Connect to LiveKit
            └─ Denied → Show error message (Arabic)
```

## Error Handling

```
┌─────────────────────────────────────────────────────────────┐
│ Error Types and Recovery                                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ 1. Configuration Errors                                       │
│    ├─ Missing API key → Show Arabic config message          │
│    ├─ Invalid token → Show connection error                  │
│    └─ Invalid URL → Show connection error                    │
│                                                               │
│ 2. Permission Errors                                          │
│    ├─ Microphone denied → "يجب السماح باستخدام الميكروفون"  │
│    └─ Recovery: Link to settings                             │
│                                                               │
│ 3. Connection Errors                                          │
│    ├─ LiveKit connection failed → "فشل الاتصال"             │
│    ├─ Network error → "تحقق من الاتصال بالإنترنت"           │
│    └─ Recovery: Retry button                                 │
│                                                               │
│ 4. API Errors                                                 │
│    ├─ Gemini rate limit → Fallback gracefully               │
│    ├─ Gemini error → "عذراً، حدث خطأ"                       │
│    └─ Recovery: Show cached response if available            │
│                                                               │
│ 5. Audio Errors                                               │
│    ├─ Microphone not working → "الميكروفون لا يعمل"         │
│    ├─ Speaker not working → Show text response              │
│    └─ Recovery: Text-only mode                               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Security Architecture

```
┌────────────────────────────────────────────────────────────┐
│ Security Layers                                             │
├────────────────────────────────────────────────────────────┤
│                                                              │
│ Layer 1: Configuration                                       │
│  ├─ Environment variables (build-time)                      │
│  ├─ No hardcoded keys in code                              │
│  └─ .gitignore protection                                   │
│                                                              │
│ Layer 2: API Keys                                            │
│  ├─ Gemini API key (server-side recommended)               │
│  ├─ LiveKit token (generated per-session)                  │
│  └─ Token expiration handling                               │
│                                                              │
│ Layer 3: Network                                             │
│  ├─ HTTPS/WSS only (encrypted)                             │
│  ├─ Certificate validation                                  │
│  └─ No sensitive data in logs                               │
│                                                              │
│ Layer 4: Permissions                                         │
│  ├─ Runtime permission checks                               │
│  ├─ Minimal permissions requested                           │
│  └─ User consent required                                   │
│                                                              │
│ Layer 5: Data                                                │
│  ├─ No persistent storage of audio                         │
│  ├─ Temporary conversation cache only                       │
│  └─ User can clear history                                  │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

## Farm Context Integration

```
┌──────────────────────────────────────────────────────────┐
│ Farm Model (Provider)                                     │
├──────────────────────────────────────────────────────────┤
│                                                            │
│ Data Sources:                                              │
│  ├─ Firebase Firestore (real-time)                        │
│  ├─ Backend API (REST)                                    │
│  └─ Local cache                                            │
│                                                            │
│ Available Data:                                            │
│  ├─ vegetation: List<String>                              │
│  │   └─ ["طماطم", "خيار", "فلفل"]                        │
│  │                                                         │
│  ├─ pumpStatus: PumpStatus                                │
│  │   └─ "تعمل" / "متوقفة"                                │
│  │                                                         │
│  ├─ soilMoisture: double                                  │
│  │   └─ 65% (رطبة)                                       │
│  │                                                         │
│  ├─ tankWater: double                                     │
│  │   └─ 80% (ممتلئ)                                      │
│  │                                                         │
│  └─ weatherAlert: String                                  │
│      └─ "لا توجد تنبيهات"                                │
│                                                            │
└──────────────────┬───────────────────────────────────────┘
                   │
                   │ Context passed to Gemini
                   ▼
    ┌──────────────────────────────────────┐
    │ Gemini AI (Arabic Agricultural Bot)  │
    │                                       │
    │ Understands:                          │
    │  - Plant names in Arabic             │
    │  - Farm equipment status             │
    │  - Sensor readings                   │
    │  - Agricultural terminology          │
    │  - Tunisian farming practices        │
    └──────────────────────────────────────┘
```

## UI Component Hierarchy

```
VegetationDisplayWidget (StatefulWidget)
│
├─ Consumer<FarmModel>
│  └─ Card (Main container)
│     └─ Padding
│        └─ Column
│           │
│           ├─ Row (Header)
│           │  ├─ Icon (eco)
│           │  ├─ Text ("النباتات المزروعة")
│           │  ├─ Spacer
│           │  ├─ ConnectionIndicator (if connected)
│           │  └─ CircularProgressIndicator (if loading)
│           │
│           ├─ VegetationDisplay
│           │  ├─ Wrap (vegetation chips)
│           │  │  └─ VegetationChip × n
│           │  └─ Text (total count)
│           │
│           ├─ Divider
│           │
│           └─ VoiceChatSection
│              ├─ Row (Header)
│              │  ├─ Icon (voice)
│              │  └─ Text ("محادثة صوتية بالعربية")
│              │
│              ├─ Container (Status)
│              │  ├─ Icon (status indicator)
│              │  └─ Text (_statusMessage)
│              │
│              ├─ Container (Last Response)
│              │  ├─ Row (Header)
│              │  │  ├─ Icon (assistant)
│              │  │  └─ Text ("آخر رد")
│              │  └─ Text (_lastResponse)
│              │
│              └─ Row (Control Buttons)
│                 ├─ ElevatedButton ("بدء/قطع")
│                 └─ IconButton (test)
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Production Deployment                                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ Mobile App (Flutter)                                          │
│  └─ Built with environment variables                         │
│     └─ flutter build apk --dart-define=...                  │
│                                                               │
│ Backend Service (Recommended)                                 │
│  ├─ User authentication                                      │
│  ├─ LiveKit token generation (per-session)                  │
│  ├─ API key management                                       │
│  ├─ Rate limiting                                            │
│  └─ Usage monitoring                                         │
│                                                               │
│ LiveKit Server                                                │
│  ├─ Cloud: livekit.cloud                                    │
│  └─ Self-hosted: Docker container                           │
│                                                               │
│ Google Cloud Services                                         │
│  ├─ Gemini API (AI responses)                               │
│  ├─ Speech-to-Text (voice input)                            │
│  └─ Text-to-Speech (voice output)                           │
│                                                               │
│ Monitoring & Analytics                                        │
│  ├─ API usage tracking                                       │
│  ├─ Error logging                                            │
│  ├─ Performance metrics                                      │
│  └─ User interaction analytics                               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Future Enhancements

```
Phase 1: Current Implementation ✅
 ├─ LiveKit connection setup
 ├─ Gemini AI integration
 ├─ Arabic UI
 ├─ Test mode
 └─ Documentation

Phase 2: Speech Implementation 🔄
 ├─ Google Speech-to-Text
 ├─ Google Text-to-Speech
 ├─ Real-time audio processing
 └─ Voice quality optimization

Phase 3: Advanced Features 🔮
 ├─ Voice commands ("شغل المضخة")
 ├─ Conversation history
 ├─ Offline mode
 ├─ Multi-language support
 └─ Voice shortcuts

Phase 4: Enterprise Features 🚀
 ├─ Backend token service
 ├─ User authentication
 ├─ Analytics dashboard
 ├─ A/B testing
 └─ Performance monitoring
```

---

**Architecture Version**: 1.0
**Last Updated**: 2025-11-02
**Status**: Implementation Complete, Testing Pending
