"""
Irrigation Decision Service
Handles AI-powered irrigation decisions using XGBoost + Gemini
"""

import sys
import os
from datetime import datetime, timedelta
from typing import Dict, Optional

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..'))

# Handle imports for running from backend/ or parent directory
try:
    from utils.firebase_client import get_db
    from services.weather_service import get_weather_forecast
except ImportError:
    from backend.utils.firebase_client import get_db
    from backend.services.weather_service import get_weather_forecast

from firebase_admin import firestore

# Import decision maker
_decision_maker = None

try:
    from utils.gemini_decision import GeminiIrrigationDecision
except ImportError:
    try:
        from backend.utils.gemini_decision import GeminiIrrigationDecision
    except ImportError:
        GeminiIrrigationDecision = None

def get_decision_maker():
    global _decision_maker
    if _decision_maker is None and GeminiIrrigationDecision is not None:
        try:
            _decision_maker = GeminiIrrigationDecision()
        except Exception as e:
            print(f"Warning: Could not initialize GeminiIrrigationDecision: {e}")
    return _decision_maker


def calculate_season(day_of_year: int) -> int:
    """Calculate season from day of year"""
    if 80 <= day_of_year <= 172:
        return 1  # spring
    elif 173 <= day_of_year <= 265:
        return 2  # summer
    elif 266 <= day_of_year <= 355:
        return 3  # fall
    else:
        return 4  # winter


def get_irrigation_decision(user_id: str, plant_name: str, soil_moisture: float,
                           sensor_temperature: Optional[float] = None,
                           sensor_humidity: Optional[float] = None) -> Dict:
    """
    Get AI irrigation decision for a user's plant
    
    Args:
        user_id: User ID
        plant_name: Plant to water
        soil_moisture: Current soil moisture (%)
        sensor_temperature: Optional temperature override
        sensor_humidity: Optional humidity override
        
    Returns:
        Decision with reasoning
    """
    db = get_db()
    
    # Get user profile
    user_ref = db.collection('users').document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        return {
            'success': False,
            'error': f'User {user_id} not found'
        }
    
    user_profile = user_doc.to_dict()
    
    # Check AI mode
    if not user_profile.get('ai_mode', True):
        return {
            'success': False,
            'error': 'AI mode is disabled for this user. Use manual valve control.',
            'ai_mode': False
        }
    
    # Check if currently watering
    watering_state = user_profile.get('watering_state', {})
    now_dt = datetime.now()
    
    if watering_state.get('is_watering'):
        expected_end_iso = watering_state.get('expected_end')
        try:
            expected_end_dt = datetime.fromisoformat(expected_end_iso) if expected_end_iso else None
        except Exception:
            expected_end_dt = None
        
        if expected_end_dt and expected_end_dt > now_dt:
            # Watering in progress
            remaining_min = int((expected_end_dt - now_dt).total_seconds() / 60) + 1
            return {
                'success': True,
                'watering_in_progress': True,
                'remaining_minutes': remaining_min,
                'message': f"Watering already in progress for '{watering_state.get('plant_name')}'."
            }
        else:
            # Expired - clear it
            try:
                user_ref.update({'watering_state': firestore.DELETE_FIELD})
            except Exception:
                pass
    
    # Get plant features
    plant_features = None
    for plant in user_profile.get('plants', []):
        if plant['name'].lower() == plant_name.lower():
            plant_features = plant['features']
            break
    
    if not plant_features:
        return {
            'success': False,
            'error': f'Plant {plant_name} not found in user profile'
        }
    
    # Get weather forecast
    location = user_profile.get('location', 'Tunis')
    weather_data = get_weather_forecast(location)
    
    if not weather_data['success']:
        return {
            'success': False,
            'error': 'Failed to get weather forecast'
        }
    
    # Get last watering time
    last_watering = user_profile.get('last_watering')
    if last_watering:
        last_watering_time = datetime.fromisoformat(last_watering)
        minutes_since = int((now_dt - last_watering_time).total_seconds() / 60)
    else:
        minutes_since = 1440  # Default: 24 hours
    
    # Prepare sensor data
    day_of_year = now_dt.timetuple().tm_yday
    
    sensor_data = {
        'soil_moisture': soil_moisture,
        'current_temperature': sensor_temperature or weather_data['current']['temperature'],
        'current_humidity': sensor_humidity or weather_data['current']['humidity'],
        'minutes_since_last_watering': minutes_since,
        'water_requirement_level': plant_features['water_requirement_level'],
        'root_depth_cm': plant_features['root_depth_cm'],
        'drought_tolerance': plant_features['drought_tolerance'],
        'soil_type_encoded': user_profile['soil_properties']['soil_type_encoded'],
        'soil_type': user_profile['soil_properties']['soil_type'],
        'soil_compaction': user_profile['soil_properties']['soil_compaction'],
        'slope_degrees': user_profile['soil_properties']['slope_degrees'],
        'hour_of_day': now_dt.hour,
        'day_of_year': day_of_year,
        'season': calculate_season(day_of_year)
    }
    
    # Get irrigation decision
    decision_maker = get_decision_maker()
    
    if decision_maker:
        decision = decision_maker.decide(
            sensor_data,
            weather_data['hourly_rain_probability'],
            weather_data['hourly_precipitation_mm']
        )
    else:
        # Fallback: simple rule-based decision
        decision = {
            'final_decision': {
                'should_water': soil_moisture < plant_features['critical_moisture_threshold'],
                'duration_minutes': 30,
                'intensity_percent': 70,
                'confidence': 0.7
            },
            'reasoning': 'Fallback decision (AI models not available)',
            'xgboost_predictions': {}
        }
    
    # If decision is to water, update watering state
    if decision['final_decision']['should_water']:
        duration_minutes = int(decision['final_decision'].get('duration_minutes', 0))
        start_time = datetime.now()
        expected_end = start_time + timedelta(minutes=duration_minutes)
        
        new_watering_state = {
            'is_watering': True,
            'plant_name': plant_name,
            'start_time': start_time.isoformat(),
            'expected_end': expected_end.isoformat(),
            'mode': 'ai',
            'duration_minutes': duration_minutes
        }
        
        user_ref.update({
            'last_watering': start_time.isoformat(),
            'watering_state': new_watering_state
        })
    
    # Log decision
    log_ref = db.collection('irrigation_logs').document()
    log_ref.set({
        'user_id': user_id,
        'plant_name': plant_name,
        'timestamp': datetime.now().isoformat(),
        'sensor_data': sensor_data,
        'decision': decision['final_decision'],
        'reasoning': decision['reasoning'],
        'mode': 'ai'
    })
    
    return {
        'success': True,
        'decision': decision['final_decision'],
        'reasoning': decision['reasoning'],
        'weather': {
            'current': weather_data['current'],
            'total_rain_24h': sum(weather_data['hourly_precipitation_mm']),
            'max_rain_probability': max(weather_data['hourly_rain_probability'])
        }
    }


def get_irrigation_history(user_id: str, limit: int = 50) -> Dict:
    """Get irrigation history for a user"""
    db = get_db()
    
    try:
        logs_ref = db.collection('irrigation_logs')\
                     .where('user_id', '==', user_id)\
                     .order_by('timestamp', direction=firestore.Query.DESCENDING)\
                     .limit(limit)
        
        logs = []
        for doc in logs_ref.stream():
            log_data = doc.to_dict()
            logs.append(log_data)
        
        return {
            'success': True,
            'count': len(logs),
            'logs': logs
        }
        
    except Exception as e:
        return {
            'success': False,
            'error': str(e)
        }
