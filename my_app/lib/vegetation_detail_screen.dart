import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'farm_model.dart';

class VegetationDetailScreen extends StatelessWidget {
  final VegetationType vegetationType;

  const VegetationDetailScreen({
    super.key,
    required this.vegetationType,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          title: Text(
            FarmModel.getVegetationName(vegetationType),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FarmModel.getVegetationColor(vegetationType),
                  FarmModel.getVegetationColor(vegetationType).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
        ),
        body: Consumer<FarmModel>(
          builder: (context, farm, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 100),
                    // Soil Moisture and Pump Status side by side
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            title: 'رطوبة التربة',
                            imagePath: farm.getSoilMoistureImage(),
                            value: farm.getSoilMoistureText(),
                            color: farm.getMainStatusColor(),
                            icon: Icons.water_drop,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoTile(
                            title: 'المضخة',
                            imagePath: farm.getPumpImage(),
                            value: farm.getPumpStatusText(),
                            color: farm.getPumpStatusColor(),
                            icon: Icons.water,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Control Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 26,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00BCD4), Color(0xFF4CAF50)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'التحكم',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Control Mode Tile
                    _buildControlModeTile(context, farm),
                    const SizedBox(height: 16),

                    // Manual Valve Control (only visible in manual mode)
                    if (farm.controlMode == ControlMode.manual)
                      _buildManualValveControlTile(context, farm),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String imagePath,
    required String value,
    required Color color,
    required IconData icon,
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
                  color: color.withOpacity(0.1),
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
                        child: Icon(icon, size: 30, color: Colors.grey),
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
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Value
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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

  Widget _buildControlModeTile(BuildContext context, FarmModel farm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'وضع التحكم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  label: 'تلقائي',
                  icon: Icons.settings_suggest_rounded,
                  isSelected: farm.controlMode == ControlMode.automatic,
                  onTap: () => farm.setControlMode(ControlMode.automatic),
                  color: const Color(0xFF00BCD4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModeButton(
                  label: 'يدوي',
                  icon: Icons.back_hand_rounded,
                  isSelected: farm.controlMode == ControlMode.manual,
                  onTap: () => farm.setControlMode(ControlMode.manual),
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: isSelected 
            ? LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) 
            : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 0 : 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ] : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[500],
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualValveControlTile(BuildContext context, FarmModel farm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'التحكم بالصمام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Current status indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  farm.getValveStatusColor().withOpacity(0.2),
                  farm.getValveStatusColor().withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.water_drop_rounded,
                  color: farm.getValveStatusColor(),
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  'الصمام ${farm.getValveStatusText()}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: farm.getValveStatusColor(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Control buttons
          Row(
            children: [
              Expanded(
                child: _buildValveButton(
                  label: 'فتح الصمام',
                  icon: Icons.water_drop_rounded,
                  onTap: () => farm.openValve(),
                  color: const Color(0xFF4CAF50),
                  isActive: farm.valveStatus == ValveStatus.open,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildValveButton(
                  label: 'إغلاق الصمام',
                  icon: Icons.block_rounded,
                  onTap: () => farm.closeValve(),
                  color: const Color(0xFFF44336),
                  isActive: farm.valveStatus == ValveStatus.closed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValveButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required bool isActive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: isActive 
            ? LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) 
            : null,
          color: isActive ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.grey[300]!,
            width: isActive ? 0 : 2,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ] : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[500],
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
