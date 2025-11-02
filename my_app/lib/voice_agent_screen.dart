import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'farm_model.dart';

class VoiceAgentScreen extends StatefulWidget {
  const VoiceAgentScreen({super.key});

  @override
  _VoiceAgentScreenState createState() => _VoiceAgentScreenState();
}

class _VoiceAgentScreenState extends State<VoiceAgentScreen> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late AnimationController _animationController;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _text = '';
  String _response = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('ar-SA'); // Arabic
    _flutterTts.setSpeechRate(0.5); // Slower for clarity
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() {
            _isListening = false;
            _response = 'عذراً، حدث خطأ. حاول مرة أخرى.';
          });
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _text = '';
          _response = '';
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
              if (val.finalResult) {
                _isListening = false;
                _processCommand(_text);
              }
            });
          },
          localeId: 'ar_SA',
        );
      } else {
        setState(() {
          _response = 'عذراً، الميكروفون غير متاح.';
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processCommand(String command) {
    final farm = Provider.of<FarmModel>(context, listen: false);
    String response = '';
    
    String lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('شغل المضخة') || lowerCommand.contains('شغّل المضخة')) {
      farm.setPumpStatus(PumpStatus.on);
      response = 'تم تشغيل المضخة بنجاح.';
    } else if (lowerCommand.contains('اقفل المضخة') || lowerCommand.contains('أقفل المضخة') || lowerCommand.contains('طفي المضخة')) {
      farm.setPumpStatus(PumpStatus.off);
      response = 'تم إقفال المضخة.';
    } else if (lowerCommand.contains('كيف حال أرضي') || lowerCommand.contains('كيف المزرعة') || lowerCommand.contains('كيف الأرض')) {
      response = 'الأرض ${farm.getMainStatusText()}. ${farm.getMainStatusSubText()}';
    } else if (lowerCommand.contains('هل أحتاج أن أروي') || lowerCommand.contains('متى أروي') || lowerCommand.contains('هل أروي')) {
      response = farm.getMainStatusSubText();
    } else if (lowerCommand.contains('المضخة شغالة') || lowerCommand.contains('حالة المضخة') || lowerCommand.contains('وين المضخة')) {
      response = 'المضخة ${farm.getPumpStatusText()}.';
    } else if (lowerCommand.contains('كم بقي في الخزان') || lowerCommand.contains('الماء') || lowerCommand.contains('الخزان')) {
      response = 'الماء في الخزان ${farm.getTankWaterText()}.';
    } else if (lowerCommand.contains('الطقس') || lowerCommand.contains('الجو')) {
      response = 'تنبيه الطقس: ${farm.getWeatherAlertText()}.';
    } else if (lowerCommand.contains('رطوبة') || lowerCommand.contains('التربة')) {
      response = 'رطوبة التربة ${farm.getSoilMoistureText()}.';
    } else {
      response = 'لم أفهم سؤالك. حاول أن تسأل بطريقة أخرى.';
    }

    setState(() => _response = response);
    _speak(response);
  }

  void _speak(String text) async {
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(text);
    setState(() => _isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'كلم أرضك 🎤',
          style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00BCD4), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 80),
                // Header Instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00BCD4).withOpacity(0.1),
                        const Color(0xFF4CAF50).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00BCD4).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded, 
                          color: Color(0xFF00BCD4), 
                          size: 28
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'إضغط على الزر واسأل عن مزرعتك بصوتك',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Visual Feedback Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_text.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'أنت:',
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          _text,
                                          style: GoogleFonts.cairo(
                                            fontSize: 17,
                                            color: Colors.black87,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                          ],
                          if (_response.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF00BCD4), Color(0xFF26C6DA)],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00BCD4).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'المساعد:',
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00BCD4).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          _response,
                                          style: GoogleFonts.cairo(
                                            fontSize: 17,
                                            color: Colors.black87,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_text.isEmpty && _response.isEmpty)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline_rounded, 
                                      size: 60, 
                                      color: Colors.grey[300]
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'ابدأ المحادثة بالضغط على الزر',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // The Main Interaction Button
                GestureDetector(
                  onTap: _listen,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [const Color(0xFF2196F3), const Color(0xFF1976D2)]
                                : _isSpeaking
                                    ? [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)]
                                    : [const Color(0xFF00BCD4), const Color(0xFF00ACC1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening 
                                  ? const Color(0xFF2196F3) 
                                  : _isSpeaking 
                                      ? const Color(0xFF9C27B0)
                                      : const Color(0xFF00BCD4))
                                  .withOpacity(0.4),
                              blurRadius: _isListening ? 30 : 20,
                              spreadRadius: _isListening ? 8 : 3,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isListening
                                  ? Icons.mic_rounded
                                  : _isSpeaking
                                      ? Icons.volume_up_rounded
                                      : Icons.mic_none_rounded,
                              size: 70,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _isListening
                                  ? 'بيستمع لك...'
                                  : _isSpeaking
                                      ? 'بيجاوبك...'
                                      : 'إضغط واسأل',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Status Text
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isListening 
                        ? const Color(0xFF2196F3).withOpacity(0.1)
                        : _isSpeaking
                            ? const Color(0xFF9C27B0).withOpacity(0.1)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isListening
                        ? 'اسأل سؤالك الآن...'
                        : _isSpeaking
                            ? 'استمع للإجابة...'
                            : 'جاهز للاستماع',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      color: _isListening 
                          ? const Color(0xFF2196F3)
                          : _isSpeaking
                              ? const Color(0xFF9C27B0)
                              : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}