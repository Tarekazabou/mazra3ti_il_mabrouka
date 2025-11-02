import 'package:flutter/material.dart';
import 'firebase_service.dart';

enum SoilMoisture { dry, moderate, wet }
enum PumpStatus { on, off }
enum TankWater { full, half, low }
enum WeatherAlert { rainTomorrow, veryHot, nothing }
enum ControlMode { manual, automatic }
enum ValveStatus { open, closed }
enum VegetationType { potato, tomato, onion }

class FarmModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  SoilMoisture _soilMoisture = SoilMoisture.moderate;
  PumpStatus _pumpStatus = PumpStatus.off;
  TankWater _tankWater = TankWater.half;
  WeatherAlert _weatherAlert = WeatherAlert.nothing;
  ControlMode _controlMode = ControlMode.automatic;
  ValveStatus _valveStatus = ValveStatus.closed;
  List<String> _vegetation = [];
  String? _farmerId;
  String? _farmerName;
  bool _isLoading = false;

  SoilMoisture get soilMoisture => _soilMoisture;
  PumpStatus get pumpStatus => _pumpStatus;
  TankWater get tankWater => _tankWater;
  WeatherAlert get weatherAlert => _weatherAlert;
  ControlMode get controlMode => _controlMode;
  ValveStatus get valveStatus => _valveStatus;
  List<String> get vegetation => _vegetation;
  String? get farmerId => _farmerId;
  String? get farmerName => _farmerName;
  bool get isLoading => _isLoading;

  void setSoilMoisture(SoilMoisture value) {
    _soilMoisture = value;
    notifyListeners();
  }

  void setPumpStatus(PumpStatus value) {
    _pumpStatus = value;
    notifyListeners();
  }

  void setTankWater(TankWater value) {
    _tankWater = value;
    notifyListeners();
  }

  void setWeatherAlert(WeatherAlert value) {
    _weatherAlert = value;
    notifyListeners();
  }

  void setControlMode(ControlMode value) {
    _controlMode = value;
    notifyListeners();
  }

  void setValveStatus(ValveStatus value) {
    _valveStatus = value;
    notifyListeners();
  }

  void openValve() {
    if (_controlMode == ControlMode.manual) {
      _valveStatus = ValveStatus.open;
      notifyListeners();
    }
  }

  void closeValve() {
    if (_controlMode == ControlMode.manual) {
      _valveStatus = ValveStatus.closed;
      notifyListeners();
    }
  }

  /// Load farmer data from Firebase
  Future<void> loadFarmerData(String farmerId) async {
    _isLoading = true;
    _farmerId = farmerId;
    notifyListeners();

    try {
      // Load farmer info
      final farmerData = await _firebaseService.getFarmerData(farmerId);
      if (farmerData != null) {
        _farmerName = farmerData['name'] as String?;
        
        // Load vegetation
        if (farmerData['vegetation'] is List) {
          _vegetation = (farmerData['vegetation'] as List)
              .map((v) => v.toString())
              .toList();
        }
      }

      // Load measurements
      final measurements = await _firebaseService.getMeasurements(farmerId);
      if (measurements != null) {
        _updateFromFirebaseData(measurements);
      }
    } catch (e) {
      print('Error loading farmer data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to real-time updates from Firebase
  void listenToMeasurements(String farmerId) {
    _farmerId = farmerId;
    _firebaseService.getMeasurementsStream(farmerId).listen((data) {
      if (data != null) {
        _updateFromFirebaseData(data);
        notifyListeners();
      }
    });

    _firebaseService.getFarmerDataStream(farmerId).listen((data) {
      if (data != null) {
        _farmerName = data['name'] as String?;
        if (data['vegetation'] is List) {
          _vegetation = (data['vegetation'] as List)
              .map((v) => v.toString())
              .toList();
        }
        notifyListeners();
      }
    });
  }

  /// Update local state from Firebase data
  void _updateFromFirebaseData(Map<String, dynamic> data) {
    // Soil Moisture
    if (data['soilMoisture'] != null) {
      _soilMoisture = _parseSoilMoisture(data['soilMoisture']);
    }

    // Pump Status
    if (data['pumpStatus'] != null) {
      _pumpStatus = data['pumpStatus'] == 'on' ? PumpStatus.on : PumpStatus.off;
    }

    // Tank Water
    if (data['tankWater'] != null) {
      _tankWater = _parseTankWater(data['tankWater']);
    }

    // Weather Alert
    if (data['weatherAlert'] != null) {
      _weatherAlert = _parseWeatherAlert(data['weatherAlert']);
    }

    // Control Mode
    if (data['controlMode'] != null) {
      _controlMode = data['controlMode'] == 'manual' 
          ? ControlMode.manual 
          : ControlMode.automatic;
    }

    // Valve Status
    if (data['valveStatus'] != null) {
      _valveStatus = data['valveStatus'] == 'open' 
          ? ValveStatus.open 
          : ValveStatus.closed;
    }
  }

  SoilMoisture _parseSoilMoisture(String value) {
    switch (value.toLowerCase()) {
      case 'dry':
        return SoilMoisture.dry;
      case 'wet':
        return SoilMoisture.wet;
      default:
        return SoilMoisture.moderate;
    }
  }

  TankWater _parseTankWater(String value) {
    switch (value.toLowerCase()) {
      case 'full':
        return TankWater.full;
      case 'low':
        return TankWater.low;
      default:
        return TankWater.half;
    }
  }

  WeatherAlert _parseWeatherAlert(String value) {
    switch (value.toLowerCase()) {
      case 'raintomorrow':
        return WeatherAlert.rainTomorrow;
      case 'veryhot':
        return WeatherAlert.veryHot;
      default:
        return WeatherAlert.nothing;
    }
  }

  String getMainStatusText() {
    if (_soilMoisture == SoilMoisture.dry) {
      return "الأرض تحتاج للماء!";
    } else if (_soilMoisture == SoilMoisture.moderate) {
      return "الأرض عطشى قليلاً";
    } else {
      return "الأرض بخير";
    }
  }

  String getMainStatusSubText() {
    if (_soilMoisture == SoilMoisture.dry) {
      return "شغّل المضخة";
    } else if (_soilMoisture == SoilMoisture.moderate) {
      return "يمكنك الري في المساء";
    } else {
      return "لا حاجة للري الآن";
    }
  }

  Color getMainStatusColor() {
    if (_soilMoisture == SoilMoisture.dry) {
      return Colors.red;
    } else if (_soilMoisture == SoilMoisture.moderate) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  IconData getMainStatusIcon() {
    if (_soilMoisture == SoilMoisture.dry) {
      return Icons.local_fire_department; // dry/alert
    } else if (_soilMoisture == SoilMoisture.moderate) {
      return Icons.eco; // moderate plant
    } else {
      return Icons.park; // healthy/happy
    }
  }

  IconData getWeatherIcon() {
    switch (_weatherAlert) {
      case WeatherAlert.rainTomorrow:
        return Icons.cloud;
      case WeatherAlert.veryHot:
        return Icons.wb_sunny;
      case WeatherAlert.nothing:
        return Icons.check_circle;
    }
  }

  String getSoilMoistureText() {
    switch (_soilMoisture) {
      case SoilMoisture.dry:
        return "جافة";
      case SoilMoisture.moderate:
        return "معتدلة";
      case SoilMoisture.wet:
        return "رطبة";
    }
  }

  String getSoilMoistureImage() {
    switch (_soilMoisture) {
      case SoilMoisture.dry:
        return "assets/images/soil_dry.png";
      case SoilMoisture.moderate:
        return "assets/images/soil_moderate.png";
      case SoilMoisture.wet:
        return "assets/images/soil_wet.png";
    }
  }

  String getPumpStatusText() {
    return _pumpStatus == PumpStatus.on ? "شغالة" : "مقفولة";
  }

  Color getPumpStatusColor() {
    return _pumpStatus == PumpStatus.on ? Colors.green : Colors.red;
  }

  String getTankWaterText() {
    switch (_tankWater) {
      case TankWater.full:
        return "كاملة";
      case TankWater.half:
        return "نص نص";
      case TankWater.low:
        return "قليلة";
    }
  }

  String getTankWaterImage() {
    switch (_tankWater) {
      case TankWater.full:
        return "assets/images/tank_full.png";
      case TankWater.half:
        return "assets/images/tank_half.png";
      case TankWater.low:
        return "assets/images/tank_low.png";
    }
  }

  String getWeatherAlertText() {
    switch (_weatherAlert) {
      case WeatherAlert.rainTomorrow:
        return "مطر غداً";
      case WeatherAlert.veryHot:
        return "حار جداً";
      case WeatherAlert.nothing:
        return "لا شيء";
    }
  }

  String getWeatherImage() {
    switch (_weatherAlert) {
      case WeatherAlert.rainTomorrow:
        return "assets/images/weather_rain.png";
      case WeatherAlert.veryHot:
        return "assets/images/weather_hot.png";
      case WeatherAlert.nothing:
        return "assets/images/weather_good.png";
    }
  }

  String getPumpImage() {
    return _pumpStatus == PumpStatus.on 
        ? "assets/images/pump_on.png"
        : "assets/images/pump_off.png";
  }

  String getControlModeText() {
    return _controlMode == ControlMode.manual ? "يدوي" : "تلقائي";
  }

  String getValveStatusText() {
    return _valveStatus == ValveStatus.open ? "مفتوح" : "مغلق";
  }

  Color getValveStatusColor() {
    return _valveStatus == ValveStatus.open ? Colors.green : Colors.red;
  }

  // Vegetation helper methods
  static String getVegetationName(VegetationType type) {
    switch (type) {
      case VegetationType.potato:
        return "بطاطس";
      case VegetationType.tomato:
        return "طماطم";
      case VegetationType.onion:
        return "بصل";
    }
  }

  static IconData getVegetationIcon(VegetationType type) {
    switch (type) {
      case VegetationType.potato:
        return Icons.eco; // potato
      case VegetationType.tomato:
        return Icons.local_florist; // tomato
      case VegetationType.onion:
        return Icons.spa; // onion
    }
  }

  static Color getVegetationColor(VegetationType type) {
    switch (type) {
      case VegetationType.potato:
        return Colors.brown;
      case VegetationType.tomato:
        return Colors.red;
      case VegetationType.onion:
        return Colors.purple;
    }
  }

  static String getVegetationImage(VegetationType type) {
    switch (type) {
      case VegetationType.potato:
        return "assets/images/potato.png";
      case VegetationType.tomato:
        return "assets/images/tomato.png";
      case VegetationType.onion:
        return "assets/images/onion.png";
    }
  }

  // Dynamic vegetation methods (from Firebase)
  
  /// Get display name for dynamic vegetation from Firebase
  String getVegetationDisplayName(String vegetationName) {
    // Check if it matches known types first
    final lowerName = vegetationName.toLowerCase();
    if (lowerName.contains('بطاطس') || lowerName == 'potato') {
      return 'بطاطس';
    } else if (lowerName.contains('طماطم') || lowerName == 'tomato') {
      return 'طماطم';
    } else if (lowerName.contains('بصل') || lowerName == 'onion') {
      return 'بصل';
    }
    // Return as-is for custom vegetation
    return vegetationName;
  }

  /// Get icon for dynamic vegetation
  IconData getVegetationIconForName(String vegetationName) {
    final lowerName = vegetationName.toLowerCase();
    if (lowerName.contains('بطاطس') || lowerName == 'potato') {
      return Icons.eco;
    } else if (lowerName.contains('طماطم') || lowerName == 'tomato') {
      return Icons.local_florist;
    } else if (lowerName.contains('بصل') || lowerName == 'onion') {
      return Icons.spa;
    }
    // Default icon for unknown vegetation
    return Icons.grass;
  }

  /// Get color for dynamic vegetation
  Color getVegetationColorForName(String vegetationName) {
    final lowerName = vegetationName.toLowerCase();
    if (lowerName.contains('بطاطس') || lowerName == 'potato') {
      return Colors.brown;
    } else if (lowerName.contains('طماطم') || lowerName == 'tomato') {
      return Colors.red;
    } else if (lowerName.contains('بصل') || lowerName == 'onion') {
      return Colors.purple;
    }
    // Default color for unknown vegetation
    return Colors.green;
  }

  /// Check if has any vegetation
  bool hasVegetation() {
    return _vegetation.isNotEmpty;
  }

  /// Get vegetation count
  int getVegetationCount() {
    return _vegetation.length;
  }

  /// Get formatted vegetation list as string
  String getVegetationListText() {
    if (_vegetation.isEmpty) {
      return 'لا يوجد نباتات';
    }
    return _vegetation.map((v) => getVegetationDisplayName(v)).join('، ');
  }
}