import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'farm_model.dart';

/// Widget to display all farm measurements from Firebase
class MeasurementsDisplayWidget extends StatelessWidget {
  const MeasurementsDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmModel>(
      builder: (context, model, child) {
        if (model.isLoading) {
          return const Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        return Column(
          children: [
            // Main Status Card
            _buildMainStatusCard(model),
            const SizedBox(height: 16),
            
            // Measurements Grid
            _buildMeasurementsGrid(model),
          ],
        );
      },
    );
  }

  Widget _buildMainStatusCard(FarmModel model) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              model.getMainStatusColor(),
              model.getMainStatusColor().withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              model.getMainStatusIcon(),
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              model.getMainStatusText(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              model.getMainStatusSubText(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsGrid(FarmModel model) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMeasurementCard(
                  title: 'رطوبة التربة',
                  value: model.getSoilMoistureText(),
                  icon: Icons.water_drop,
                  color: _getSoilMoistureColor(model.soilMoisture),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMeasurementCard(
                  title: 'الخزان',
                  value: model.getTankWaterText(),
                  icon: Icons.water,
                  color: _getTankWaterColor(model.tankWater),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMeasurementCard(
                  title: 'المضخة',
                  value: model.getPumpStatusText(),
                  icon: Icons.settings_input_antenna,
                  color: model.getPumpStatusColor(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMeasurementCard(
                  title: 'الصمام',
                  value: model.getValveStatusText(),
                  icon: Icons.tune,
                  color: model.getValveStatusColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMeasurementCard(
                  title: 'الطقس',
                  value: model.getWeatherAlertText(),
                  icon: model.getWeatherIcon(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMeasurementCard(
                  title: 'وضع التحكم',
                  value: model.getControlModeText(),
                  icon: Icons.settings,
                  color: model.controlMode == ControlMode.manual 
                      ? Colors.orange 
                      : Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getSoilMoistureColor(SoilMoisture moisture) {
    switch (moisture) {
      case SoilMoisture.dry:
        return Colors.orange;
      case SoilMoisture.moderate:
        return Colors.amber;
      case SoilMoisture.wet:
        return Colors.blue;
    }
  }

  Color _getTankWaterColor(TankWater level) {
    switch (level) {
      case TankWater.full:
        return Colors.green;
      case TankWater.half:
        return Colors.amber;
      case TankWater.low:
        return Colors.red;
    }
  }
}
