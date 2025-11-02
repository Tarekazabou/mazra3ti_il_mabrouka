import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livekit_client/livekit_client.dart' as livekit;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'farm_model.dart';
import 'voice_chat_config.dart';

/// Widget showing vegetation with LiveKit + Gemini voice chat (Arabic only)
class VegetationDisplayWidget extends StatefulWidget {
  const VegetationDisplayWidget({super.key});

  @override
  State<VegetationDisplayWidget> createState() => _VegetationDisplayWidgetState();
}

class _VegetationDisplayWidgetState extends State<VegetationDisplayWidget> {
  // LiveKit components
  livekit.Room? _room;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isListening = false;
  String _statusMessage = 'جاهز للاتصال';
  
  // Gemini AI
  GenerativeModel? _geminiModel;
  ChatSession? _chatSession;
  final List<Map<String, String>> _conversationHistory = [];
  String _lastResponse = '';
  
  // Voice interaction state
  bool _isSpeaking = false;
  final StringBuffer _transcriptBuffer = StringBuffer();

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  @override
  void dispose() {
    _disconnectFromLiveKit();
    super.dispose();
  }

  /// Initialize Gemini AI with Arabic language support
  void _initializeGemini() {
    try {
      // Check if configuration is valid
      if (!VoiceChatConfig.isConfigured()) {
        setState(() {
          _statusMessage = VoiceChatConfig.getConfigStatusMessage();
        });
        return;
      }
      
      _geminiModel = GenerativeModel(
        model: VoiceChatConfig.geminiModel,
        apiKey: VoiceChatConfig.geminiApiKey,
        systemInstruction: Content.system(VoiceChatConfig.geminiSystemInstruction),
      );
      
      _chatSession = _geminiModel!.startChat();
      
      setState(() {
        _statusMessage = 'جاهز للمحادثة الصوتية';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في تهيئة Gemini: $e';
      });
    }
  }

  /// Connect to LiveKit room for voice chat
  Future<void> _connectToLiveKit() async {
    if (_isConnecting || _isConnected) return;

    setState(() {
      _isConnecting = true;
      _statusMessage = 'جاري الاتصال...';
    });

    try {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        throw Exception('PERMISSION_DENIED: يجب السماح باستخدام الميكروفون');
      }

      // Initialize LiveKit room
      _room = livekit.Room();
      
      // Set up event listeners
      _room!.addListener(_onRoomUpdate);
      
      // Connect to LiveKit server using configuration
      await _room!.connect(
        VoiceChatConfig.livekitUrl,
        VoiceChatConfig.livekitToken,
      );
      
      // Enable microphone
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      
      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _statusMessage = 'متصل - ابدأ الحديث';
      });

      // Start listening to audio
      _startAudioProcessing();
      
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _statusMessage = 'فشل الاتصال: $e';
      });
    }
  }

  /// Disconnect from LiveKit
  Future<void> _disconnectFromLiveKit() async {
    if (_room != null) {
      await _room!.disconnect();
      _room?.removeListener(_onRoomUpdate);
      _room = null;
    }
    
    setState(() {
      _isConnected = false;
      _isListening = false;
      _statusMessage = 'تم قطع الاتصال';
    });
  }

  /// Handle room updates
  void _onRoomUpdate() {
    // Handle room state changes
    final room = _room;
    if (room != null) {
      // Check room connection state
      if (room.connectionState == livekit.ConnectionState.disconnected) {
        setState(() {
          _isConnected = false;
          _statusMessage = 'انقطع الاتصال';
        });
      }
    }
  }

  /// Start processing audio from LiveKit
  void _startAudioProcessing() {
    setState(() {
      _isListening = true;
      _statusMessage = 'استمع لك...';
    });
    
    // Listen to remote audio tracks using the listener pattern
    _room!.createListener().on<livekit.TrackSubscribedEvent>((event) {
      final track = event.track;
      if (track is livekit.RemoteAudioTrack) {
        _processAudioTrack(track);
      }
    });
  }

  /// Process audio track and send to Gemini
  void _processAudioTrack(livekit.RemoteAudioTrack track) {
    // TODO: Implement full voice pipeline
    // 1. Convert audio to text using speech-to-text (Google Cloud Speech-to-Text)
    // 2. Send text to Gemini
    // 3. Get response and convert to speech (Google Cloud Text-to-Speech)
    // 4. Send speech back through LiveKit
    // See: https://cloud.google.com/speech-to-text
    // See: https://cloud.google.com/text-to-speech
    
    // For now, we'll simulate the flow
    _simulateVoiceInteraction();
  }

  /// Simulate voice interaction (placeholder for actual implementation)
  void _simulateVoiceInteraction() async {
    // TODO: Replace with actual implementation
    // This is a placeholder. In production:
    // - Use Google Speech-to-Text API to convert audio to text
    // - Process with Gemini (already implemented in _queryGemini)
    // - Use Text-to-Speech to convert response back to audio
    // - Stream audio through LiveKit
    
    setState(() {
      _statusMessage = 'جاري المعالجة...';
    });
  }

  /// Send text query to Gemini and get response
  Future<String> _queryGemini(String query) async {
    if (_chatSession == null) {
      return 'عذراً، النظام غير جاهز';
    }

    try {
      // Capture farm data at the start to avoid stale data during async operation
      final farm = Provider.of<FarmModel>(context, listen: false);
      final farmVegetation = farm.hasVegetation() ? farm.vegetation.join('، ') : 'لا يوجد نباتات';
      final farmVegCount = farm.getVegetationCount();
      final pumpStatus = farm.getPumpStatusText();
      final soilMoisture = farm.getSoilMoistureText();
      final tankWater = farm.getTankWaterText();
      
      // Build context from farm data
      final contextMessage = '''
معلومات المزرعة الحالية:
- النباتات المزروعة: $farmVegetation
- عدد النباتات: $farmVegCount
- حالة المضخة: $pumpStatus
- رطوبة التربة: $soilMoisture
- حالة الخزان: $tankWater

سؤال المزارع: $query
''';

      final response = await _chatSession!.sendMessage(
        Content.text(contextMessage),
      );

      final responseText = response.text ?? 'عذراً، لم أستطع فهم السؤال';
      
      // Store in conversation history
      _conversationHistory.add({
        'user': query,
        'assistant': responseText,
      });

      return responseText;
    } catch (e) {
      return 'عذراً، حدث خطأ: $e';
    }
  }

  /// Test voice chat with a sample query
  Future<void> _testVoiceChat() async {
    setState(() {
      _isSpeaking = true;
      _statusMessage = 'جاري الاستماع...';
    });

    // Simulate receiving a voice query
    await Future.delayed(const Duration(seconds: 1));
    
    const sampleQuery = 'ما هي النباتات الموجودة في مزرعتي؟';
    
    setState(() {
      _statusMessage = 'جاري المعالجة...';
    });

    final response = await _queryGemini(sampleQuery);
    
    setState(() {
      _lastResponse = response;
      _isSpeaking = false;
      _statusMessage = 'مكتمل - اضغط للاستماع مرة أخرى';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmModel>(
      builder: (context, model, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with voice chat button
                Row(
                  children: [
                    const Icon(Icons.eco, color: Colors.green, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      'النباتات المزروعة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Voice chat indicator
                    if (_isConnected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'متصل',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (model.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Vegetation display
                if (model.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (!model.hasVegetation())
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.grass, size: 48, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'لا يوجد نباتات مضافة',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: model.vegetation.map((veg) {
                          return _buildVegetationChip(
                            context,
                            veg,
                            model.getVegetationIconForName(veg),
                            model.getVegetationColorForName(veg),
                            model.getVegetationDisplayName(veg),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'العدد الإجمالي: ${model.getVegetationCount()}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                
                // Voice chat section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.record_voice_over,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'محادثة صوتية بالعربية',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Status message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isConnected 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isConnected 
                                ? Icons.check_circle
                                : Icons.info_outline,
                            size: 20,
                            color: _isConnected ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Last response display
                    if (_lastResponse.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.assistant,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'آخر رد:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _lastResponse,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    
                    // Control buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isConnecting ? null : (_isConnected 
                                ? _disconnectFromLiveKit 
                                : _connectToLiveKit),
                            icon: Icon(_isConnected 
                                ? Icons.stop 
                                : Icons.mic),
                            label: Text(_isConnected 
                                ? 'قطع الاتصال' 
                                : 'بدء المحادثة الصوتية'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isConnected 
                                  ? Colors.red 
                                  : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        if (_isConnected) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _isSpeaking ? null : _testVoiceChat,
                            icon: const Icon(Icons.chat),
                            tooltip: 'اختبار المحادثة',
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVegetationChip(
    BuildContext context,
    String veg,
    IconData icon,
    Color color,
    String displayName,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
