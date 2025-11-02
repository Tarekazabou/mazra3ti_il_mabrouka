import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'api_service.dart';

enum SoilMoisture { dry, moderate, wet }
enum PumpStatus { on, off }
enum TankWater { full, half, low }
enum WeatherAlert { rainTomorrow, veryHot, nothing }
enum ControlMode { manual, automatic }
enum ValveStatus { open, closed }
enum VegetationType { potato, tomato, onion }

class FarmModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final ApiService _apiService = ApiService();
  
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
  // Last AI decision cache to drive main status card
  Map<String, dynamic>? _lastAiDecision; // contents of 'decision' from backend
  Map<String, dynamic>? _lastAiReasoning; // contents of 'reasoning' from backend
  bool _aiWateringInProgress = false;
  int? _aiRemainingMinutes;

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

  // ===== BACKEND API METHODS =====

  /// Load farm state from backend API
  Future<void> loadFarmStateFromApi(String farmerId) async {
    print('🔵 loadFarmStateFromApi called for farmer: $farmerId');
    _isLoading = true;
    _farmerId = farmerId;
    notifyListeners();

    try {
      print('🔵 Fetching farm state from API...');
      final farmState = await _apiService.getFarmState(farmerId);
      print('🔵 API Response: $farmState');
      
      if (farmState != null && farmState['success'] == true) {
        print('✅ Farm state loaded successfully!');
        
        // Update farmer info
        if (farmState['user'] != null) {
          _farmerName = farmState['user']['name'] as String?;
          print('👤 Farmer name: $_farmerName');
        }

        // Update vegetation from plants (actual user data!)
        if (farmState['plants'] is List) {
          print('🌱 Raw plants data: ${farmState['plants']}');
          _vegetation = (farmState['plants'] as List)
              .map((p) => p['name'].toString())
              .toList();
          print('🌱 Loaded plants into _vegetation: $_vegetation');
          print('🌱 _vegetation list length: ${_vegetation.length}');
        } else {
          print('⚠️ No plants found in farmState or not a List');
        }

        // Update valve status (actual real-time status!)
        if (farmState['valve'] != null) {
          final valve = farmState['valve'];
          _valveStatus = valve['is_watering'] == true 
              ? ValveStatus.open 
              : ValveStatus.closed;
          
          // Update control mode based on valve mode
          if (valve['mode'] == 'manual') {
            _controlMode = ControlMode.manual;
          }
        }

        // Update AI mode (from user settings)
        if (farmState['ai_mode'] != null) {
          _controlMode = farmState['ai_mode'] == true 
              ? ControlMode.automatic 
              : ControlMode.manual;
          print('AI mode: ${_controlMode == ControlMode.automatic ? "Auto" : "Manual"}');
        }

        // Update weather data (real weather for user's location!)
        if (farmState['weather'] != null) {
          final weather = farmState['weather'];
          
          // Parse weather alerts from real data
          if (weather['will_rain_soon'] == true) {
            _weatherAlert = WeatherAlert.rainTomorrow;
          } else if (weather['temperature'] != null && weather['temperature'] > 35) {
            _weatherAlert = WeatherAlert.veryHot;
          } else {
            _weatherAlert = WeatherAlert.nothing;
          }
          
          print('Weather updated: ${weather['summary']}');
        }

        // Set realistic defaults for other values
        // In a real app, these would also come from sensors
        // For now, set reasonable defaults
        _soilMoisture = SoilMoisture.moderate;
        _pumpStatus = PumpStatus.off;
        _tankWater = TankWater.half;

        print('✅ All farm data loaded successfully');
        print('📊 Final _vegetation: $_vegetation (count: ${_vegetation.length})');
        notifyListeners();
        print('🔔 notifyListeners() called - UI should update now!');
      } else {
        print('❌ farmState is null or success != true');
      }
    } catch (e) {
      print('❌ Error loading farm state from API: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('🏁 Loading complete, isLoading = false');
    }
  }

  /// Open valve via backend API
  Future<bool> openValveViaApi(String plantName, int durationMinutes) async {
    if (_farmerId == null) return false;
    
    try {
      final result = await _apiService.openValve(
        _farmerId!, 
        plantName, 
        durationMinutes,
      );
      
      if (result != null && result['success'] == true) {
        _valveStatus = ValveStatus.open;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error opening valve via API: $e');
      return false;
    }
  }

  /// Close valve via backend API
  Future<bool> closeValveViaApi() async {
    if (_farmerId == null) return false;
    
    try {
      final result = await _apiService.closeValve(_farmerId!);
      
      if (result != null && result['success'] == true) {
        _valveStatus = ValveStatus.closed;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error closing valve via API: $e');
      return false;
    }
  }

  /// Toggle AI mode via backend API
  Future<bool> toggleAiModeViaApi(bool enabled) async {
    if (_farmerId == null) return false;
    
    try {
      final result = await _apiService.toggleAiMode(_farmerId!, enabled);
      
      if (result != null && result['success'] == true) {
        _controlMode = enabled ? ControlMode.automatic : ControlMode.manual;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error toggling AI mode via API: $e');
      return false;
    }
  }

  /// Get irrigation history from backend API
  Future<List<Map<String, dynamic>>> getHistoryFromApi({int limit = 10}) async {
    if (_farmerId == null) return [];
    
    try {
      return await _apiService.getHistory(_farmerId!, limit: limit);
    } catch (e) {
      print('Error getting history from API: $e');
      return [];
    }
  }

  /// Request AI decision from backend API
  Future<Map<String, dynamic>?> requestAiDecision({String? plantName, double? soilMoisture}) async {
    if (_farmerId == null) return null;
    try {
      final selectedPlant = plantName ?? (_vegetation.isNotEmpty ? _vegetation.first : 'tomato');
      final double moisture = soilMoisture ?? _estimateSoilMoisturePercent();
      final result = await _apiService.getAiDecisionFor(
        _farmerId!,
        plantName: selectedPlant,
        soilMoisture: moisture,
      );

      // Cache AI result to drive the main status card
      if (result != null && result['success'] == true) {
        _aiWateringInProgress = result['watering_in_progress'] == true;
        _aiRemainingMinutes = result['remaining_minutes'] is int ? result['remaining_minutes'] : null;
        if (result['decision'] is Map<String, dynamic>) {
          _lastAiDecision = Map<String, dynamic>.from(result['decision']);
        }
        if (result['reasoning'] is Map<String, dynamic>) {
          _lastAiReasoning = Map<String, dynamic>.from(result['reasoning']);
        }
        notifyListeners();
      }
      return result;
    } catch (e) {
      print('Error requesting AI decision: $e');
      return null;
    }
  }

  double _estimateSoilMoisturePercent() {
    switch (_soilMoisture) {
      case SoilMoisture.dry:
        return 20.0;
      case SoilMoisture.moderate:
        return 50.0;
      case SoilMoisture.wet:
        return 80.0;
    }
  }

  /// Check if backend is available
  Future<bool> checkBackendHealth() async {
    try {
      return await _apiService.checkHealth();
    } catch (e) {
      print('Error checking backend health: $e');
      return false;
    }
  }

  // ===== END BACKEND API METHODS =====


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
    // Prefer AI recommendation if available
    if (_aiWateringInProgress) {
      final mins = _aiRemainingMinutes;
      return mins != null ? 'الري قيد التنفيذ — متبقٍ $mins دقيقة' : 'الري قيد التنفيذ';
    }
    if (_lastAiDecision != null) {
      final shouldWater = _lastAiDecision!['should_water'] == true;
      if (shouldWater) return 'اسقِ الآن';
      return 'لا تسق الآن';
    }
    // Fallback to moisture-based static messages
    if (_soilMoisture == SoilMoisture.dry) {
      return "الأرض تحتاج للماء!";
    } else if (_soilMoisture == SoilMoisture.moderate) {
      return "الأرض عطشى قليلاً";
    } else {
      return "الأرض بخير";
    }
  }

  String getMainStatusSubText() {
    // Prefer AI details if available
    if (_aiWateringInProgress) {
      final mins = _aiRemainingMinutes;
      return mins != null ? 'عملية الري بدأت بالفعل. المتبقي: $mins دقيقة' : 'عملية الري بدأت بالفعل';
    }
    if (_lastAiDecision != null) {
      final shouldWater = _lastAiDecision!['should_water'] == true;
      final duration = _lastAiDecision!['duration_minutes'];
      final intensity = _lastAiDecision!['intensity_percent'];
      if (shouldWater) {
        return 'مدة الري الموصى بها: ${duration ?? '-'} دقيقة • الشدة: ${intensity ?? '-'}%';
      }
      // If not watering, show reasoning if available
      if (_lastAiReasoning != null) {
        final rationale = _lastAiReasoning!['decision_rationale']?.toString() ?? '';
        if (rationale.isNotEmpty && rationale.length < 100) {
          return rationale;
        }
      }
      return 'التربة مناسبة، لا حاجة للري الآن';
    }
    // Fallback
    if (_soilMoisture == SoilMoisture.dry) {
      return "شغّل المضخة";
    } else if (_soilMoisture == SoilMoisture.moderate) {
      return "يمكنك الري في المساء";
    } else {
      return "لا حاجة للري الآن";
    }
  }

  Color getMainStatusColor() {
    // Prefer AI signal if available
    if (_aiWateringInProgress) {
      return Colors.green;
    }
    if (_lastAiDecision != null) {
      final shouldWater = _lastAiDecision!['should_water'] == true;
      return shouldWater ? Colors.green : const Color(0xFF00BCD4);
    }
    // Fallback to previous logic
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
    return  _valveStatus == ValveStatus.open 
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

  

  // Dynamic vegetation methods (from Firebase)
  
  /// Get display name for dynamic vegetation from Firebase (with full Tunisia crops support)
  String getVegetationDisplayName(String vegetationName) {
    final lowerName = vegetationName.toLowerCase().replaceAll('_', ' ');
    
    // Arabic translations for all Tunisia crops
    final translations = {
      'potato': 'بطاطس',
      'tomato': 'طماطم',
      'onion': 'بصل',
      'wheat': 'قمح',
      'barley': 'شعير',
      'olive': 'زيتون',
      'date palm': 'نخيل التمر',
      'date': 'تمر',
      'palm': 'نخيل',
      'citrus': 'حمضيات',
      'pepper': 'فلفل',
      'eggplant': 'باذنجان',
      'cucumber': 'خيار',
      'watermelon': 'شمام',
      'melon': 'بطيخ',
      'grape': 'عنب',
      'almond': 'لوز',
    };
    
    // Check if we have a translation
    for (var entry in translations.entries) {
      if (lowerName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Capitalize first letter of English names
    return vegetationName.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Get icon for dynamic vegetation (supports all Tunisia crops)
  IconData getVegetationIconForName(String vegetationName) {
    final lowerName = vegetationName.toLowerCase().replaceAll('_', ' ');
    
    // Vegetables
    if (lowerName.contains('potato') || lowerName.contains('بطاطس')) {
      return Icons.eco;
    } else if (lowerName.contains('tomato') || lowerName.contains('طماطم')) {
      return Icons.local_florist;
    } else if (lowerName.contains('onion') || lowerName.contains('بصل')) {
      return Icons.spa;
    } else if (lowerName.contains('pepper') || lowerName.contains('فلفل')) {
      return Icons.local_fire_department;
    } else if (lowerName.contains('eggplant') || lowerName.contains('باذنجان')) {
      return Icons.eco_outlined;
    } else if (lowerName.contains('cucumber') || lowerName.contains('خيار')) {
      return Icons.grass;
    }
    // Fruits
    else if (lowerName.contains('olive') || lowerName.contains('زيتون')) {
      return Icons.circle;
    } else if (lowerName.contains('date') || lowerName.contains('palm') || lowerName.contains('تمر') || lowerName.contains('نخيل')) {
      return Icons.park;
    } else if (lowerName.contains('citrus') || lowerName.contains('orange') || lowerName.contains('برتقال')) {
      return Icons.wb_sunny;
    } else if (lowerName.contains('grape') || lowerName.contains('عنب')) {
      return Icons.bubble_chart;
    } else if (lowerName.contains('almond') || lowerName.contains('لوز')) {
      return Icons.nature;
    } else if (lowerName.contains('watermelon') || lowerName.contains('بطيخ')) {
      return Icons.water_drop;
    } else if (lowerName.contains('melon') || lowerName.contains('شمام')) {
      return Icons.circle_outlined;
    }
    // Cereals
    else if (lowerName.contains('wheat') || lowerName.contains('قمح')) {
      return Icons.grain;
    } else if (lowerName.contains('barley') || lowerName.contains('شعير')) {
      return Icons.grass_outlined;
    }
    
    // Default icon for unknown vegetation
    return Icons.agriculture;
  }

  /// Get color for dynamic vegetation (supports all Tunisia crops)
  Color getVegetationColorForName(String vegetationName) {
    final lowerName = vegetationName.toLowerCase().replaceAll('_', ' ');
    
    // Vegetables
    if (lowerName.contains('potato') || lowerName.contains('بطاطس')) {
      return Colors.brown;
    } else if (lowerName.contains('tomato') || lowerName.contains('طماطم')) {
      return Colors.red;
    } else if (lowerName.contains('onion') || lowerName.contains('بصل')) {
      return Colors.purple;
    } else if (lowerName.contains('pepper') || lowerName.contains('فلفل')) {
      return Colors.orange;
    } else if (lowerName.contains('eggplant') || lowerName.contains('باذنجان')) {
      return const Color(0xFF6A0DAD);
    } else if (lowerName.contains('cucumber') || lowerName.contains('خيار')) {
      return Colors.green;
    }
    // Fruits
    else if (lowerName.contains('olive') || lowerName.contains('زيتون')) {
      return const Color(0xFF808000);
    } else if (lowerName.contains('date') || lowerName.contains('palm') || lowerName.contains('تمر')) {
      return const Color(0xFF8B4513);
    } else if (lowerName.contains('citrus') || lowerName.contains('orange') || lowerName.contains('برتقال')) {
      return Colors.orange;
    } else if (lowerName.contains('grape') || lowerName.contains('عنب')) {
      return Colors.purple;
    } else if (lowerName.contains('almond') || lowerName.contains('لوز')) {
      return const Color(0xFFD2691E);
    } else if (lowerName.contains('watermelon') || lowerName.contains('بطيخ')) {
      return const Color(0xFFDC143C);
    } else if (lowerName.contains('melon') || lowerName.contains('شمام')) {
      return const Color(0xFFFFD700);
    }
    // Cereals
    else if (lowerName.contains('wheat') || lowerName.contains('قمح')) {
      return const Color(0xFFF5DEB3);
    } else if (lowerName.contains('barley') || lowerName.contains('شعير')) {
      return const Color(0xFFDAA520);
    }
    
    // Default color for unknown vegetation
    return const Color(0xFF4CAF50);
  }

  /// Get image asset path for dynamic vegetation (supports many crops)
  /// Falls back to a generic produce image if no specific asset is found.
  String getVegetationImageForName(String vegetationName) {
    final lowerName = vegetationName.toLowerCase().replaceAll('_', ' ');

    // Core set (lowercase filenames)
    if (lowerName.contains('potato') || lowerName.contains('بطاطس')) {
      return 'assets/images/potato.png';
    } else if (lowerName.contains('tomato') || lowerName.contains('طماطم')) {
      return 'assets/images/tomato.png';
    } else if (lowerName.contains('onion') || lowerName.contains('بصل')) {
      return 'assets/images/onion.png';
    }

    // Vegetables (PascalCase filenames)
    if (lowerName.contains('pepper') || lowerName.contains('فلفل')) {
      return 'assets/images/Pepper.png';
    } else if (lowerName.contains('cucumber') || lowerName.contains('خيار')) {
      return 'assets/images/Cucumber.png';
    } else if (lowerName.contains('eggplant') || lowerName.contains('باذنجان')) {
      return 'assets/images/Eggplant.png';
    } else if (lowerName.contains('cabbage')) {
      return 'assets/images/Cabbage.png';
    } else if (lowerName.contains('carrot')) {
      return 'assets/images/Carrot.png';
    } else if (lowerName.contains('garlic')) {
      return 'assets/images/Garlic.png';
    } else if (lowerName.contains('beetroot')) {
      return 'assets/images/Beetroot.png';
    } else if (lowerName.contains('radish')) {
      return 'assets/images/Radish.png';
    } else if (lowerName.contains('turnip')) {
      return 'assets/images/Turnip.png';
    }

    // Fruits (PascalCase filenames)
    if (lowerName.contains('grape') || lowerName.contains('عنب')) {
      return 'assets/images/Grapes.png';
    } else if (lowerName.contains('apple')) {
      return 'assets/images/Apple.png';
    } else if (lowerName.contains('apricot')) {
      return 'assets/images/Apricot.png';
    } else if (lowerName.contains('fig')) {
      return 'assets/images/Fig.png';
    } else if (lowerName.contains('peach')) {
      return 'assets/images/Peach.png';
    } else if (lowerName.contains('pear')) {
      return 'assets/images/Pear.png';
    } else if (lowerName.contains('plum')) {
      return 'assets/images/Plum.png';
    } else if (lowerName.contains('pomegranate')) {
      return 'assets/images/Pomegranate.png';
    } else if (lowerName.contains('nectarine')) {
      return 'assets/images/Nectarine.png';
    } else if (lowerName.contains('strawberry')) {
      return 'assets/images/Strawberry.png';
    } else if (lowerName.contains('raspberry')) {
      return 'assets/images/Raspberry.png';
    }

    // Unknown or currently unsupported crops (olive, date, citrus, almond, melon, wheat, barley, etc.)
    // Fall back to a generic produce image.
    return 'assets/images/Apple.png';
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