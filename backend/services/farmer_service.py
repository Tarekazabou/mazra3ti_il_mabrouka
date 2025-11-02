"""
Farmer Service
Handles operations for women farmers' mobile interface
"""

from datetime import datetime
from typing import Dict

# Handle imports for running from backend/ or parent directory
try:
    from utils.firebase_client import get_db
    from services.valve_service import get_valve_status
    from services.weather_service import get_weather_summary
except ImportError:
    from backend.utils.firebase_client import get_db
    from backend.services.valve_service import get_valve_status
    from backend.services.weather_service import get_weather_summary


def get_farm_state(user_id: str) -> Dict:
    """
    Get complete farm state for mobile app display
    
    Returns:
        - User profile (name, location, plants)
        - Current watering status
        - Weather summary
        - AI mode status
        - Recent activity
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
    
    user_data = user_doc.to_dict()
    
    # Get valve status
    valve_status = get_valve_status(user_id)
    
    # Get weather
    location = user_data.get('location', 'Tunis')
    weather = get_weather_summary(location)
    
    # Get recent logs (last 5)
    try:
        from firebase_admin import firestore
        logs_ref = db.collection('irrigation_logs')\
                     .where('user_id', '==', user_id)\
                     .order_by('timestamp', direction=firestore.Query.DESCENDING)\
                     .limit(5)
        
        recent_logs = []
        for doc in logs_ref.stream():
            log = doc.to_dict()
            recent_logs.append({
                'timestamp': log['timestamp'],
                'plant_name': log.get('plant_name'),
                'action': log.get('action', 'decision'),
                'should_water': log.get('decision', {}).get('should_water', False)
            })
    except Exception:
        recent_logs = []
    
    # Build farm state
    farm_state = {
        'success': True,
        'user': {
            'name': user_data.get('name'),
            'location': user_data.get('location'),
            'email': user_data.get('email')
        },
        'plants': [
            {
                'name': p['name'],
                'area_sqm': p.get('area_sqm')
            }
            for p in user_data.get('plants', [])
        ],
        'valve': {
            'is_watering': valve_status.get('is_watering', False),
            'remaining_minutes': valve_status.get('remaining_minutes', 0),
            'plant_name': valve_status.get('plant_name'),
            'mode': valve_status.get('watering_mode')
        },
        'ai_mode': user_data.get('ai_mode', True),
        'weather': weather if weather.get('success') else None,
        'last_watering': user_data.get('last_watering'),
        'recent_activity': recent_logs
    }
    
    return farm_state


def get_user_plants(user_id: str) -> Dict:
    """Get list of user's plants"""
    db = get_db()
    user_ref = db.collection('users').document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        return {
            'success': False,
            'error': f'User {user_id} not found'
        }
    
    user_data = user_doc.to_dict()
    plants = user_data.get('plants', [])
    
    return {
        'success': True,
        'plants': [
            {
                'name': p['name'],
                'area_sqm': p.get('area_sqm'),
                'water_requirement': p.get('features', {}).get('water_requirement_level'),
                'drought_tolerance': p.get('features', {}).get('drought_tolerance')
            }
            for p in plants
        ]
    }
