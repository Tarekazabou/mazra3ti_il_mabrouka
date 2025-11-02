"""
Valve Control Service
Handles manual valve operations and AI mode toggle
"""

from datetime import datetime, timedelta
from typing import Dict

# Handle imports for running from backend/ or parent directory
try:
    from utils.firebase_client import get_db
except ImportError:
    from backend.utils.firebase_client import get_db
from firebase_admin import firestore


def open_valve_manual(user_id: str, plant_name: str, duration_minutes: int) -> Dict:
    """
    Manually open valve to start watering (farmer override)
    
    Args:
        user_id: User ID
        plant_name: Plant being watered
        duration_minutes: How long to water
        
    Returns:
        Status and watering_state
    """
    db = get_db()
    user_ref = db.collection('users').document(user_id)
    
    # Check if user exists
    user_doc = user_ref.get()
    if not user_doc.exists:
        return {
            'success': False,
            'error': f'User {user_id} not found'
        }
    
    # Check if already watering
    user_data = user_doc.to_dict()
    watering_state = user_data.get('watering_state', {})
    
    if watering_state.get('is_watering'):
        expected_end_iso = watering_state.get('expected_end')
        try:
            expected_end_dt = datetime.fromisoformat(expected_end_iso) if expected_end_iso else None
            if expected_end_dt and expected_end_dt > datetime.now():
                return {
                    'success': False,
                    'error': 'Watering already in progress',
                    'watering_state': watering_state
                }
        except Exception:
            pass
    
    # Start watering
    start_time = datetime.now()
    expected_end = start_time + timedelta(minutes=duration_minutes)
    
    new_watering_state = {
        'is_watering': True,
        'plant_name': plant_name,
        'start_time': start_time.isoformat(),
        'expected_end': expected_end.isoformat(),
        'mode': 'manual',  # Track that this was manual
        'duration_minutes': duration_minutes
    }
    
    user_ref.update({
        'last_watering': start_time.isoformat(),
        'watering_state': new_watering_state
    })
    
    # Log the manual action
    log_ref = db.collection('irrigation_logs').document()
    log_ref.set({
        'user_id': user_id,
        'plant_name': plant_name,
        'timestamp': start_time.isoformat(),
        'action': 'manual_open',
        'duration_minutes': duration_minutes,
        'decision': {
            'should_water': True,
            'duration_minutes': duration_minutes,
            'mode': 'manual'
        },
        'reasoning': 'Manual valve control by farmer'
    })
    
    return {
        'success': True,
        'message': f'Valve opened manually for {duration_minutes} minutes',
        'watering_state': new_watering_state
    }


def close_valve_manual(user_id: str) -> Dict:
    """
    Manually close valve to stop watering (farmer override)
    
    Args:
        user_id: User ID
        
    Returns:
        Status
    """
    db = get_db()
    user_ref = db.collection('users').document(user_id)
    
    # Check if user exists
    user_doc = user_ref.get()
    if not user_doc.exists:
        return {
            'success': False,
            'error': f'User {user_id} not found'
        }
    
    # Clear watering state
    user_ref.update({'watering_state': firestore.DELETE_FIELD})
    
    # Log the manual action
    log_ref = db.collection('irrigation_logs').document()
    log_ref.set({
        'user_id': user_id,
        'timestamp': datetime.now().isoformat(),
        'action': 'manual_close',
        'decision': {
            'should_water': False,
            'mode': 'manual'
        },
        'reasoning': 'Manual valve close by farmer'
    })
    
    return {
        'success': True,
        'message': 'Valve closed manually, watering stopped'
    }


def set_ai_mode(user_id: str, ai_mode: bool) -> Dict:
    """
    Toggle AI automatic mode on/off
    
    Args:
        user_id: User ID
        ai_mode: True = AI makes decisions, False = manual only
        
    Returns:
        Status
    """
    db = get_db()
    user_ref = db.collection('users').document(user_id)
    
    # Check if user exists
    user_doc = user_ref.get()
    if not user_doc.exists:
        return {
            'success': False,
            'error': f'User {user_id} not found'
        }
    
    user_ref.update({
        'ai_mode': ai_mode,
        'ai_mode_updated_at': datetime.now().isoformat()
    })
    
    mode_text = "enabled" if ai_mode else "disabled"
    
    return {
        'success': True,
        'ai_mode': ai_mode,
        'message': f'AI automatic mode {mode_text}'
    }


def get_valve_status(user_id: str) -> Dict:
    """
    Get current valve/watering status for a user
    
    Returns:
        Valve state, AI mode, remaining time if watering
    """
    db = get_db()
    user_ref = db.collection('users').document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        return {
            'success': False,
            'error': f'User {user_id} not found'
        }
    
    user_data = user_doc.to_dict()
    watering_state = user_data.get('watering_state', {})
    ai_mode = user_data.get('ai_mode', True)
    
    # Check if watering is active
    is_watering = False
    remaining_minutes = 0
    
    if watering_state.get('is_watering'):
        expected_end_iso = watering_state.get('expected_end')
        try:
            expected_end_dt = datetime.fromisoformat(expected_end_iso) if expected_end_iso else None
            if expected_end_dt and expected_end_dt > datetime.now():
                is_watering = True
                remaining_minutes = int((expected_end_dt - datetime.now()).total_seconds() / 60) + 1
            else:
                # Expired - clear it
                user_ref.update({'watering_state': firestore.DELETE_FIELD})
        except Exception:
            pass
    
    return {
        'success': True,
        'is_watering': is_watering,
        'remaining_minutes': remaining_minutes if is_watering else 0,
        'plant_name': watering_state.get('plant_name') if is_watering else None,
        'watering_mode': watering_state.get('mode', 'unknown') if is_watering else None,
        'ai_mode': ai_mode,
        'last_watering': user_data.get('last_watering')
    }
