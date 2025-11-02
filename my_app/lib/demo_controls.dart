import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'farm_model.dart';

class DemoControls extends StatelessWidget {
  const DemoControls({super.key});

  @override
  Widget build(BuildContext context) {
    final farm = Provider.of<FarmModel>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'التحكم بالتجربة',
            style: GoogleFonts.amiri(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.green[700],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'استخدم هذه الإعدادات لاختبار التطبيق في حالات مختلفة',
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Soil Moisture Control
              _buildSectionTitle('رطوبة التربة'),
              _buildCard(
                child: Column(
                  children: [
                    _buildRadioTile<SoilMoisture>(
                      title: 'جافة 🌵',
                      subtitle: 'الأرض تحتاج للماء',
                      value: SoilMoisture.dry,
                      groupValue: farm.soilMoisture,
                      onChanged: (value) => farm.setSoilMoisture(value!),
                    ),
                    _buildRadioTile<SoilMoisture>(
                      title: 'معتدلة 🥀',
                      subtitle: 'الأرض عطشى قليلاً',
                      value: SoilMoisture.moderate,
                      groupValue: farm.soilMoisture,
                      onChanged: (value) => farm.setSoilMoisture(value!),
                    ),
                    _buildRadioTile<SoilMoisture>(
                      title: 'رطبة 🪴',
                      subtitle: 'الأرض بخير',
                      value: SoilMoisture.wet,
                      groupValue: farm.soilMoisture,
                      onChanged: (value) => farm.setSoilMoisture(value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pump Status Control
              _buildSectionTitle('حالة المضخة'),
              _buildCard(
                child: Column(
                  children: [
                    _buildRadioTile<PumpStatus>(
                      title: 'شغالة ⚙️',
                      subtitle: 'المضخة تعمل الآن',
                      value: PumpStatus.on,
                      groupValue: farm.pumpStatus,
                      onChanged: (value) => farm.setPumpStatus(value!),
                    ),
                    _buildRadioTile<PumpStatus>(
                      title: 'مقفولة ⭕',
                      subtitle: 'المضخة متوقفة',
                      value: PumpStatus.off,
                      groupValue: farm.pumpStatus,
                      onChanged: (value) => farm.setPumpStatus(value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tank Water Control
              _buildSectionTitle('مياه الخزان'),
              _buildCard(
                child: Column(
                  children: [
                    _buildRadioTile<TankWater>(
                      title: 'كاملة 💧💧💧',
                      subtitle: 'الخزان ممتلئ',
                      value: TankWater.full,
                      groupValue: farm.tankWater,
                      onChanged: (value) => farm.setTankWater(value!),
                    ),
                    _buildRadioTile<TankWater>(
                      title: 'نص نص 💧💧',
                      subtitle: 'الخزان نصف ممتلئ',
                      value: TankWater.half,
                      groupValue: farm.tankWater,
                      onChanged: (value) => farm.setTankWater(value!),
                    ),
                    _buildRadioTile<TankWater>(
                      title: 'قليلة 💧',
                      subtitle: 'الخزان شبه فارغ',
                      value: TankWater.low,
                      groupValue: farm.tankWater,
                      onChanged: (value) => farm.setTankWater(value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Weather Alert Control
              _buildSectionTitle('تنبيه الطقس'),
              _buildCard(
                child: Column(
                  children: [
                    _buildRadioTile<WeatherAlert>(
                      title: 'مطر غداً ⛈️',
                      subtitle: 'أمطار متوقعة',
                      value: WeatherAlert.rainTomorrow,
                      groupValue: farm.weatherAlert,
                      onChanged: (value) => farm.setWeatherAlert(value!),
                    ),
                    _buildRadioTile<WeatherAlert>(
                      title: 'حار جداً ☀️',
                      subtitle: 'طقس حار',
                      value: WeatherAlert.veryHot,
                      groupValue: farm.weatherAlert,
                      onChanged: (value) => farm.setWeatherAlert(value!),
                    ),
                    _buildRadioTile<WeatherAlert>(
                      title: 'لا شيء ✅',
                      subtitle: 'طقس عادي',
                      value: WeatherAlert.nothing,
                      groupValue: farm.weatherAlert,
                      onChanged: (value) => farm.setWeatherAlert(value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Control Mode Control
              _buildSectionTitle('وضع التحكم'),
              _buildCard(
                child: Column(
                  children: [
                    _buildRadioTile<ControlMode>(
                      title: 'تلقائي 🤖',
                      subtitle: 'النظام يتحكم تلقائياً',
                      value: ControlMode.automatic,
                      groupValue: farm.controlMode,
                      onChanged: (value) => farm.setControlMode(value!),
                    ),
                    _buildRadioTile<ControlMode>(
                      title: 'يدوي ✋',
                      subtitle: 'التحكم اليدوي بالصمام',
                      value: ControlMode.manual,
                      groupValue: farm.controlMode,
                      onChanged: (value) => farm.setControlMode(value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Valve Status Control (only if manual mode)
              if (farm.controlMode == ControlMode.manual) ...[
                _buildSectionTitle('حالة الصمام'),
                _buildCard(
                  child: Column(
                    children: [
                      _buildRadioTile<ValveStatus>(
                        title: 'مفتوح 🟢',
                        subtitle: 'الصمام مفتوح',
                        value: ValveStatus.open,
                        groupValue: farm.valveStatus,
                        onChanged: (value) => farm.setValveStatus(value!),
                      ),
                      _buildRadioTile<ValveStatus>(
                        title: 'مغلق 🔴',
                        subtitle: 'الصمام مغلق',
                        value: ValveStatus.closed,
                        groupValue: farm.valveStatus,
                        onChanged: (value) => farm.setValveStatus(value!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: GoogleFonts.amiri(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return RadioListTile<T>(
      title: Text(
        title,
        style: GoogleFonts.amiri(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.amiri(
          fontSize: 15,
          color: Colors.grey[600],
        ),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Colors.green[700],
    );
  }
}
