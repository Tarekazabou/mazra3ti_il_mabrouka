import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'farm_model.dart';

/// Widget showing vegetation with LiveKit + Gemini voice chat (Arabic only)
class VegetationDisplayWidget extends StatefulWidget {
  const VegetationDisplayWidget({super.key});

  @override
  State<VegetationDisplayWidget> createState() => _VegetationDisplayWidgetState();
}

class _VegetationDisplayWidgetState extends State<VegetationDisplayWidget> {
  // LiveKit components
  Room? _room;
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
      // Get API key from environment or use a placeholder
      // In production, this should come from secure storage or env variables
      const apiKey = String.fromEnvironment('GEMINI_API_KEY', 
          defaultValue: 'YOUR_GEMINI_API_KEY_HERE');
      
      _geminiModel = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        systemInstruction: Content.system('''أنت مساعد زراعي ذكي متخصص في المزارع التونسية.
دورك هو مساعدة المزارعين في:
- معرفة حالة النباتات المزروعة
- تقديم نصائح للري والعناية بالنباتات
- الإجابة عن أسئلة حول الزراعة

قواعد مهمة:
1. استخدم اللغة العربية فقط في جميع الردود
2. كن واضحاً ومباشراً
3. استخدم لغة بسيطة يفهمها المزارعون
4. قدم معلومات عملية ومفيدة
5. كن مشجعاً وإيجابياً

عند سؤالك عن النباتات، استخدم المعلومات المتاحة من المزرعة.'''),
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
        throw Exception('يجب السماح باستخدام الميكروفون');
      }

      // Initialize LiveKit room
      _room = Room();
      
      // Set up event listeners
      _room!.addListener(_onRoomUpdate);
      
      // Connect to LiveKit server
      // In production, get these values from your LiveKit server
      const wsUrl = String.fromEnvironment('LIVEKIT_URL', 
          defaultValue: 'wss://your-livekit-server.com');
      const token = String.fromEnvironment('LIVEKIT_TOKEN',
          defaultValue: 'YOUR_LIVEKIT_TOKEN_HERE');
      
      await _room!.connect(wsUrl, token);
      
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
    if (_room?.connectionState == ConnectionState.disconnected) {
      setState(() {
        _isConnected = false;
        _statusMessage = 'انقطع الاتصال';
      });
    }
  }

  /// Start processing audio from LiveKit
  void _startAudioProcessing() {
    setState(() {
      _isListening = true;
      _statusMessage = 'استمع لك...';
    });
    
    // Listen to remote audio tracks
    _room!.onTrackSubscribed = (track, publication, participant) {
      if (track.kind == TrackType.AUDIO) {
        _processAudioTrack(track as RemoteAudioTrack);
      }
    };
  }

  /// Process audio track and send to Gemini
  void _processAudioTrack(RemoteAudioTrack track) {
    // In a full implementation, you would:
    // 1. Convert audio to text using speech-to-text
    // 2. Send text to Gemini
    // 3. Get response and convert to speech
    // 4. Send speech back through LiveKit
    
    // For now, we'll simulate the flow
    _simulateVoiceInteraction();
  }

  /// Simulate voice interaction (placeholder for actual implementation)
  void _simulateVoiceInteraction() async {
    // This is a placeholder. In production:
    // - Use Google Speech-to-Text to convert audio to text
    // - Process with Gemini
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
      final farm = Provider.of<FarmModel>(context, listen: false);
      
      // Build context from farm data
      final context = '''
معلومات المزرعة الحالية:
- النباتات المزروعة: ${farm.hasVegetation() ? farm.vegetation.join('، ') : 'لا يوجد نباتات'}
- عدد النباتات: ${farm.getVegetationCount()}
- حالة المضخة: ${farm.getPumpStatusText()}
- رطوبة التربة: ${farm.getSoilMoistureText()}
- حالة الخزان: ${farm.getTankWaterText()}

سؤال المزارع: $query
''';

      final response = await _chatSession!.sendMessage(
        Content.text(context),
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
