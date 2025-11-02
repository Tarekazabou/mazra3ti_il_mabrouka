"""
Admin Service
Handles admin operations: add/edit/delete users, manage data
"""

from datetime import datetime
from typing import Dict, List, Optional
from firebase_admin import firestore

# Handle imports for running from backend/ or parent directory
try:
    from utils.firebase_client import get_db
    from services.plant_service import get_plant_features
except ImportError:
    from backend.utils.firebase_client import get_db
    from backend.services.plant_service import get_plant_features


def add_user(email: str, name: str, location: str, 
             soil_properties: Dict, plants: List[Dict], 
             gemini_model=None) -> Dict:
    """
    Add a new farmer user (admin function)
    
    Args:
        email: User email
        name: User name (e.g., "Mabrouka")
        location: Location (e.g., "Tunis")
        soil_properties: {soil_type, soil_compaction, slope_degrees}
        plants: [{name, area_sqm}]
        gemini_model: Optional Gemini model for plant generation
        
    Returns:
        Dictionary with user_id and status
    """
    db = get_db()
    
    # Get soil type encoding
    soil_type_map = {'sandy': 1, 'loam': 2, 'clay': 3}
    soil_type = soil_properties['soil_type'].lower()
    soil_type_encoded = soil_type_map.get(soil_type, 2)
    
    # Get plant features for each plant
    plants_with_features = []
    for plant in plants:
        plant_features = get_plant_features(plant['name'], None, gemini_model)
        plants_with_features.append({
            'name': plant['name'],
            'area_sqm': plant['area_sqm'],
            'features': plant_features
        })
    
    # Create user document
    user_ref = db.collection('users').document()
    user_id = user_ref.id
    
    user_data = {
        'user_id': user_id,
        'email': email,
        'name': name,
        'location': location,
        'soil_properties': {
            'soil_type': soil_type,
            'soil_type_encoded': soil_type_encoded,
            'soil_compaction': soil_properties['soil_compaction'],
            'slope_degrees': soil_properties['slope_degrees']
        },
        'plants': plants_with_features,
        'created_at': datetime.now().isoformat(),
        'last_watering': None,
        'ai_mode': True,  # Default: AI makes decisions
        'role': 'farmer'
    }
    
    user_ref.set(user_data)
    
    return {
        'success': True,
        'user_id': user_id,
        'message': f'User {name} added successfully',
        'plants_processed': len(plants_with_features)
    }


def update_user(user_id: str, updates: Dict) -> Dict:
    """
    Update user information
    
    Args:
        user_id: User ID
        updates: Dictionary of fields to update
        
    Returns:
        Success status
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
    
    # Update timestamp
    updates['updated_at'] = datetime.now().isoformat()
    
    user_ref.update(updates)
    
    return {
        'success': True,
        'message': f'User {user_id} updated successfully'
    }


def delete_user(user_id: str) -> Dict:
    """Delete a user"""
    db = get_db()
    user_ref = db.collection('users').document(user_id)
    
    # Check if user exists
    user_doc = user_ref.get()
    if not user_doc.exists:
        return {
            'success': False,
            'error': f'User {user_id} not found'
        }
    
    user_ref.delete()
    
    return {
        'success': True,
        'message': f'User {user_id} deleted successfully'
    }


def get_user(user_id: str) -> Dict:
    """Get user profile"""
    db = get_db()
    user_ref = db.collection('users').document(user_id)
    user_doc = user_ref.get()
    
    if not user_doc.exists:
        return {
            'success': False,
            'error': f'User {user_id} not found'
        }
    
    return {
        'success': True,
        'user': user_doc.to_dict()
    }


def list_all_users(role: Optional[str] = None) -> Dict:
    """
    List all users (admin function)
    
    Args:
        role: Filter by role ('farmer', 'admin'), None for all
        
    Returns:
        List of users
    """
    db = get_db()
    
    if role:
        users_ref = db.collection('users').where('role', '==', role)
    else:
        users_ref = db.collection('users')
    
    users = []
    for doc in users_ref.stream():
        user_data = doc.to_dict()
        # Don't return full plant features in list view
        if 'plants' in user_data:
            user_data['plants'] = [
                {'name': p['name'], 'area_sqm': p.get('area_sqm')} 
                for p in user_data['plants']
            ]
        users.append(user_data)
    
    return {
        'success': True,
        'count': len(users),
        'users': users
    }


def add_plant_to_user(user_id: str, plant_name: str, area_sqm: float, gemini_model=None) -> Dict:
    """Add a plant to a user's profile"""
    db = get_db()
    
    # Get plant features
    plant_features = get_plant_features(plant_name, user_id, gemini_model)
    
    new_plant = {
        'name': plant_name,
        'area_sqm': area_sqm,
        'features': plant_features
    }
    
    # Update user document
    user_ref = db.collection('users').document(user_id)
    user_ref.update({
        'plants': firestore.ArrayUnion([new_plant])
    })
    
    return {
        'success': True,
        'plant': new_plant,
        'message': f'Plant {plant_name} added to user {user_id}'
    }


def remove_plant_from_user(user_id: str, plant_name: str) -> Dict:
    """Remove a plant from user's profile"""
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
    
    # Filter out the plant
    updated_plants = [p for p in plants if p['name'].lower() != plant_name.lower()]
    
    if len(updated_plants) == len(plants):
        return {
            'success': False,
            'error': f'Plant {plant_name} not found in user profile'
        }
    
    user_ref.update({'plants': updated_plants})
    
    return {
        'success': True,
        'message': f'Plant {plant_name} removed from user {user_id}'
    }
