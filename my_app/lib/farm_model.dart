import 'package:flutter/material.dart';

enum SoilMoisture { dry, moderate, wet }
enum PumpStatus { on, off }
enum TankWater { full, half, low }
enum WeatherAlert { rainTomorrow, veryHot, nothing }
enum ControlMode { manual, automatic }
enum ValveStatus { open, closed }
enum VegetationType { potato, tomato, onion }

class FarmModel extends ChangeNotifier {
  SoilMoisture _soilMoisture = SoilMoisture.moderate;
  PumpStatus _pumpStatus = PumpStatus.off;
  TankWater _tankWater = TankWater.half;
  WeatherAlert _weatherAlert = WeatherAlert.nothing;
  ControlMode _controlMode = ControlMode.automatic;
  ValveStatus _valveStatus = ValveStatus.closed;

  SoilMoisture get soilMoisture => _soilMoisture;
  PumpStatus get pumpStatus => _pumpStatus;
  TankWater get tankWater => _tankWater;
  WeatherAlert get weatherAlert => _weatherAlert;
  ControlMode get controlMode => _controlMode;
  ValveStatus get valveStatus => _valveStatus;

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
}