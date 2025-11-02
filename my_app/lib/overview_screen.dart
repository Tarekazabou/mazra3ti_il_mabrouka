import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'farm_model.dart';
import 'demo_controls.dart';
import 'vegetation_detail_screen.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farm = Provider.of<FarmModel>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'مزرعتي 🌱',
              style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            if (farm.farmerName != null)
              Text(
                farm.farmerName!,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
          ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          tooltip: 'تغيير المستخدم',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث البيانات',
            onPressed: () async {
              if (farm.farmerId != null) {
                await farm.loadFarmStateFromApi(farm.farmerId!);
                // Also refresh AI recommendation to drive the main status card
                await farm.requestAiDecision();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث البيانات بنجاح'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'إعدادات التجربة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DemoControls()),
              );
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 100),
                // Main Status Card - "Is everything okay?"
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        farm.getMainStatusColor(),
                        farm.getMainStatusColor().withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: farm.getMainStatusColor().withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        // Animated plant icon with glow
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            farm.getMainStatusIcon(),
                            size: 65,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          farm.getMainStatusText(),
                          style: GoogleFonts.cairo(
                            fontSize: 34,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            farm.getMainStatusSubText(),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Farm Status Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BCD4), Color(0xFF4CAF50)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'حالة المزرعة',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Weather and Tank Status
                Row(
                  children: [
                    Expanded(
                      child: _buildTileWithImage(
                        imagePath: farm.getTankWaterImage(),
                        title: 'مياه الخزان',
                        value: farm.getTankWaterText(),
                        backgroundColor: Colors.cyan[50]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTileWithImage(
                        imagePath: farm.getWeatherImage(),
                        title: 'تنبيه الطقس',
                        value: farm.getWeatherAlertText(),
                        backgroundColor: Colors.orange[50]!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Vegetables Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BCD4), Color(0xFF4CAF50)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'أنواع المحاصيل',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Vegetation Types - Dynamic from Backend
                ...farm.vegetation.map((vegName) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDynamicVegetationTile(
                      context,
                      farm,
                      vegName,
                    ),
                  );
                }).toList(),
                
                // Show message if no plants
                if (farm.vegetation.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.grass, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text(
                            'لا يوجد نباتات مضافة',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 28),

                // Irrigation controls hooked to backend
                _buildIrrigationControls(context, farm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTileWithImage({
    required String imagePath,
    required String title,
    required String value,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cartoon Image
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to icon if image not found
                      return Center(
                        child: Icon(Icons.water_drop_rounded, size: 30, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Value
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicVegetationTile(
    BuildContext context,
    FarmModel farm,
    String vegName,
  ) {
    final color = farm.getVegetationColorForName(vegName);
    final displayName = farm.getVegetationDisplayName(vegName);
    final icon = farm.getVegetationIconForName(vegName);

    return InkWell(
      onTap: () {
        // Navigate to detail screen for this plant (dynamic crops supported)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VegetationDetailScreen(
              vegetationName: vegName,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اضغط للتحكم في هذا المحصول',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_left_rounded,
              color: Colors.grey[400],
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIrrigationControls(BuildContext context, FarmModel farm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_remote, color: Color(0xFF00BCD4), size: 26),
              const SizedBox(width: 10),
              Text(
                'التحكم في الري',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (farm.valveStatus == ValveStatus.open
                          ? Colors.green[100]
                          : Colors.red[100]) ?? Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      farm.valveStatus == ValveStatus.open
                          ? Icons.water_drop
                          : Icons.water_drop_outlined,
                      color: farm.valveStatus == ValveStatus.open
                          ? Colors.green[700]
                          : Colors.red[700],
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      farm.getValveStatusText(),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: farm.valveStatus == ValveStatus.open
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildControlButton(
                context,
                icon: Icons.play_arrow_rounded,
                label: 'تشغيل الري',
                color: const Color(0xFF4CAF50),
                onTap: () => _handleOpenValve(context, farm),
              ),
              _buildControlButton(
                context,
                icon: Icons.stop_rounded,
                label: 'إيقاف الري',
                color: const Color(0xFFF44336),
                onTap: () => _handleCloseValve(context, farm),
              ),
              _buildControlButton(
                context,
                icon: farm.controlMode == ControlMode.automatic
                    ? Icons.smart_toy
                    : Icons.pan_tool_alt,
                label: farm.controlMode == ControlMode.automatic
                    ? 'إيقاف الوضع التلقائي'
                    : 'تشغيل الوضع التلقائي',
                color: const Color(0xFF00BCD4),
                onTap: () => _handleToggleAi(context, farm),
              ),
              _buildControlButton(
                context,
                icon: Icons.online_prediction_rounded,
                label: 'توصية الذكاء الاصطناعي',
                color: const Color(0xFF7E57C2),
                onTap: () => _handleAiDecision(context, farm),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Future<void> Function() onTap,
  }) {
    return SizedBox(
      width: 220,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 3,
        ),
        icon: Icon(icon, size: 24, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onPressed: () {
          onTap();
        },
      ),
    );
  }

  Future<void> _handleOpenValve(BuildContext context, FarmModel farm) async {
    if (farm.farmerId == null) {
      _showSnack(context, 'الرجاء اختيار مزارع أولاً');
      return;
    }

    if (farm.vegetation.isEmpty) {
      _showSnack(context, 'لا يوجد محاصيل لتشغيل الري عليها');
      return;
    }

    String selectedPlant = farm.vegetation.first;
    final durationController = TextEditingController(text: '20');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'تشغيل الري',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'اختر المحصول ومدة الري بالدقائق',
                    style: GoogleFonts.cairo(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'المحصول',
                    ),
                    value: selectedPlant,
                    items: farm.vegetation
                        .map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(farm.getVegetationDisplayName(name)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedPlant = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'مدة الري (بالدقائق)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('تشغيل'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final minutes = int.tryParse(durationController.text.trim());
    if (minutes == null || minutes <= 0) {
      _showSnack(context, 'الرجاء إدخال مدة صحيحة');
      return;
    }

    _showLoadingDialog(context, 'جاري تشغيل الري...');

    final success = await farm.openValveViaApi(selectedPlant, minutes);

    Navigator.of(context, rootNavigator: true).pop();

    if (success) {
      _showSnack(context, 'تم تشغيل الري بنجاح لـ ${farm.getVegetationDisplayName(selectedPlant)}', success: true);
      await farm.loadFarmStateFromApi(farm.farmerId!);
    } else {
      _showSnack(context, 'تعذر تشغيل الري، حاول مرة أخرى');
    }
  }

  Future<void> _handleCloseValve(BuildContext context, FarmModel farm) async {
    if (farm.farmerId == null) {
      _showSnack(context, 'الرجاء اختيار مزارع أولاً');
      return;
    }

    _showLoadingDialog(context, 'جاري إيقاف الري...');
    final success = await farm.closeValveViaApi();
    Navigator.of(context, rootNavigator: true).pop();

    if (success) {
      _showSnack(context, 'تم إيقاف الري', success: true);
      await farm.loadFarmStateFromApi(farm.farmerId!);
    } else {
      _showSnack(context, 'تعذر إيقاف الري، حاول لاحقاً');
    }
  }

  Future<void> _handleToggleAi(BuildContext context, FarmModel farm) async {
    if (farm.farmerId == null) {
      _showSnack(context, 'الرجاء اختيار مزارع أولاً');
      return;
    }

    final enableAuto = farm.controlMode != ControlMode.automatic;
    _showLoadingDialog(context, enableAuto ? 'تشغيل الوضع التلقائي...' : 'إيقاف الوضع التلقائي...');

    final success = await farm.toggleAiModeViaApi(enableAuto);
    Navigator.of(context, rootNavigator: true).pop();

    if (success) {
      _showSnack(context, enableAuto ? 'تم تفعيل الوضع التلقائي' : 'تم التحول إلى الوضع اليدوي', success: true);
      await farm.loadFarmStateFromApi(farm.farmerId!);
    } else {
      _showSnack(context, 'تعذر تحديث وضع التحكم');
    }
  }

  Future<void> _handleAiDecision(BuildContext context, FarmModel farm) async {
    if (farm.farmerId == null) {
      _showSnack(context, 'الرجاء اختيار مزارع أولاً');
      return;
    }

    _showLoadingDialog(context, 'جاري طلب توصية...');
    final response = await farm.requestAiDecision();
    Navigator.of(context, rootNavigator: true).pop();

    if (response == null || response['success'] != true) {
      _showSnack(context, 'تعذر الحصول على توصية');
      return;
    }

    // Check if already watering
    if (response['watering_in_progress'] == true) {
      final remainingMin = response['remaining_minutes'] ?? 0;
      final message = 'الري جارٍ بالفعل\n$remainingMin دقيقة متبقية';
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              'حالة الري',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            content: Text(
              message,
              style: GoogleFonts.cairo(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('حسناً'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Display AI decision
    final decision = response['decision'];
    final reasoning = response['reasoning'];
    final weather = response['weather'];
    
    if (decision == null) {
      _showSnack(context, 'لا توجد بيانات قرار');
      return;
    }

    final shouldWater = decision['should_water'] == true;
    final duration = decision['duration_minutes'] ?? 0;
    final intensity = decision['intensity_percent'] ?? 0;
    
    // Build Arabic message with larger text
    String message = '';
    if (shouldWater) {
      message = '💧 يُنصح بالري\n\n';
      message += '⏱️ المدة المقترحة: $duration دقيقة\n';
      message += '💪 الشدة المقترحة: $intensity%\n\n';
    } else {
      message = '⛔ لا حاجة للري حالياً\n\n';
    }

    // Add reasoning if available - translate from English to Arabic
    if (reasoning != null) {
      final decisionRationale = reasoning['decision_rationale']?.toString() ?? '';
      final weatherAnalysis = reasoning['weather_analysis']?.toString() ?? '';
      final confidence = reasoning['confidence_level']?.toString() ?? '';
      
      if (decisionRationale.isNotEmpty) {
        // Translate common phrases to Arabic
        String arabicRationale = _translateToArabic(decisionRationale);
        message += '📝 التفسير:\n$arabicRationale\n\n';
      }
      
      if (weatherAnalysis.isNotEmpty) {
        String arabicWeather = _translateToArabic(weatherAnalysis);
        message += '🌦️ تحليل الطقس:\n$arabicWeather\n\n';
      }
      
      if (confidence.isNotEmpty) {
        final confidenceAr = confidence == 'high' ? 'عالية' : 
                            confidence == 'medium' ? 'متوسطة' : 'منخفضة';
        message += '✅ مستوى الثقة: $confidenceAr';
      }
    }

    // Add current weather if available
    if (weather != null && weather['current'] != null) {
      final temp = weather['current']['temperature'];
      final humidity = weather['current']['humidity'];
      message += '\n\n🌡️ درجة الحرارة الحالية: ${temp}°C\n';
      message += '💨 نسبة الرطوبة: ${humidity}%';
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: shouldWater 
                  ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                  : [const Color(0xFFF44336), const Color(0xFFC62828)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              shouldWater ? '💧 توصية الري' : '⛔ توصية عدم الري',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: GoogleFonts.cairo(
                fontSize: 18,
                height: 1.8,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'حسناً',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.cairo(fontSize: 15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(BuildContext context, String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: success ? Colors.green[600] : Colors.red[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _translateToArabic(String englishText) {
    // Translation map for common AI decision phrases
    final translations = {
      // Common phrases
      'Despite the rain forecast': 'على الرغم من توقعات المطر',
      'the expected precipitation is negligible': 'كمية الأمطار المتوقعة ضئيلة جداً',
      'unlikely to significantly impact soil moisture': 'من غير المحتمل أن تؤثر بشكل كبير على رطوبة التربة',
      'Maintaining the XGBoost recommendation': 'الحفاظ على توصية النموذج الذكي',
      'ensures optimal moisture levels': 'يضمن مستويات رطوبة مثالية',
      'for plant health and productivity': 'لصحة النبات وإنتاجيته',
      'plant health': 'صحة النبات',
      'productivity': 'الإنتاجية',
      
      // Weather related
      'The forecast indicates': 'تشير التوقعات إلى',
      'a high probability of rain': 'احتمالية عالية للمطر',
      'at several points': 'في عدة نقاط',
      'in the next 24 hours': 'خلال الـ 24 ساعة القادمة',
      'but the expected precipitation is minimal': 'لكن كمية الأمطار المتوقعة قليلة جداً',
      'total': 'الإجمالي',
      'no rain is expected': 'لا يُتوقع هطول أمطار',
      'Heavy rain expected': 'يُتوقع هطول أمطار غزيرة',
      'within 6 hours': 'خلال 6 ساعات',
      'Light rain': 'أمطار خفيفة',
      'Moderate rain': 'أمطار متوسطة',
      
      // Watering decisions
      'XGBoost recommends watering': 'النموذج الذكي يوصي بالري',
      'XGBoost recommends': 'النموذج الذكي يوصي',
      'with a duration of': 'بمدة',
      'and intensity of': 'وشدة',
      'based on current conditions': 'بناءً على الظروف الحالية',
      'No watering needed': 'لا حاجة للري',
      'Watering recommended': 'يُنصح بالري',
      
      // Soil conditions
      'Given the current soil moisture': 'بالنظر إلى رطوبة التربة الحالية',
      'the absence of any forecasted rain': 'وعدم وجود أي أمطار متوقعة',
      'the recommendation to not water is appropriate': 'فإن توصية عدم الري مناسبة',
      'Watering at this time would be unnecessary': 'الري في هذا الوقت غير ضروري',
      'and could lead to waterlogging': 'وقد يؤدي إلى تشبع التربة بالماء',
      'soil moisture': 'رطوبة التربة',
      'optimal moisture': 'الرطوبة المثالية',
      
      // Confidence
      'high': 'عالية',
      'medium': 'متوسطة',
      'low': 'منخفضة',
      
      // Units and numbers
      'minutes': 'دقائق',
      'minute': 'دقيقة',
      'percent': 'بالمئة',
      'mm': 'مم',
      'hours': 'ساعات',
      'hour': 'ساعة',
      'days': 'أيام',
      'day': 'يوم',
    };

    String result = englishText;
    
    // Replace phrases (longer phrases first to avoid partial replacements)
    final sortedKeys = translations.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    
    for (var key in sortedKeys) {
      result = result.replaceAll(key, translations[key]!);
    }
    
    return result;
  }

}