"""
Plant Database Service
Handles plant feature retrieval and auto-generation with Gemini AI
"""

import json
import os
import sys
from typing import Dict, Optional

# Handle imports based on whether running from backend/ or parent directory
try:
    from utils.firebase_client import get_db
except ImportError:
    from backend.utils.firebase_client import get_db

# Load plant database
_plant_database = None

def get_plant_database():
    """Load tunisia_crops_full.json from backend/data/"""
    global _plant_database
    if _plant_database is None:
        db_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'tunisia_crops_full.json')
        with open(db_path, 'r', encoding='utf-8') as f:
            _plant_database = json.load(f)
    return _plant_database


def get_plant_features(plant_name: str, user_id: str = None, gemini_model=None) -> Dict:
    """
    Get plant features from database or generate with Gemini if not found
    
    Args:
        plant_name: Name of the plant
        user_id: User ID for caching (optional)
        gemini_model: Gemini model instance for generation (optional)
        
    Returns:
        Dictionary with plant features
    """
    plant_name_lower = plant_name.lower().strip()
    db = get_db()
    
    # 1. Check local database first
    plant_db = get_plant_database()
    for crop_key, crop_data in plant_db.items():
        if crop_key.lower() == plant_name_lower or crop_data.get('name', '').lower() == plant_name_lower:
            return crop_data
    
    # 2. Check Firebase cache
    plant_ref = db.collection('plant_database').document(plant_name_lower)
    cached_plant = plant_ref.get()
    if cached_plant.exists:
        return cached_plant.to_dict()
    
    # 3. Generate with Gemini if available
    if gemini_model:
        print(f"Plant '{plant_name}' not in database. Generating with Gemini...")
        
        try:
            prompt = f"""Generate agricultural data for the plant: {plant_name}

Return ONLY valid JSON in this exact format (no markdown, no explanations):

{{
  "name": "{plant_name}",
  "water_requirement_level": <integer 1-5, where 1=low, 5=very high>,
  "optimal_moisture_range": [<min_percent>, <max_percent>],
  "critical_moisture_threshold": <percent>,
  "root_depth_cm": <integer>,
  "drought_tolerance": <integer 1-5, where 1=low tolerance, 5=high tolerance>
}}

Base your answer on agricultural knowledge. Be realistic for Tunisia's Mediterranean climate."""

            response = gemini_model.generate_content(prompt)
            response_text = response.text.strip()
            
            # Clean response
            if response_text.startswith('```json'):
                response_text = response_text.split('```json')[1].split('```')[0].strip()
            elif response_text.startswith('```'):
                response_text = response_text.split('```')[1].split('```')[0].strip()
            
            plant_data = json.loads(response_text)
            
            # Save to Firebase for future use
            plant_ref.set(plant_data)
            
            print(f"✅ Generated and cached features for {plant_name}")
            return plant_data
            
        except Exception as e:
            print(f"Error generating plant features: {e}")
    
    # 4. Return default fallback values
    return {
        'name': plant_name,
        'water_requirement_level': 3,
        'optimal_moisture_range': [50, 70],
        'critical_moisture_threshold': 30,
        'root_depth_cm': 50,
        'drought_tolerance': 3,
        'generated': 'fallback'
    }


def list_all_plants() -> list:
    """Get all plants from local database and Firebase"""
    db = get_db()
    plants = []
    
    # Local database
    plant_db = get_plant_database()
    for crop_key, crop_data in plant_db.items():
        plants.append({
            'id': crop_key,
            'name': crop_data.get('name', crop_key),
            'water_requirement_level': crop_data.get('water_requirement_level'),
            'drought_tolerance': crop_data.get('drought_tolerance'),
            'source': 'database'
        })
    
    # Custom plants from Firebase
    try:
        custom_plants_ref = db.collection('plant_database').stream()
        for doc in custom_plants_ref:
            plant_data = doc.to_dict()
            plants.append({
                'id': doc.id,
                'name': plant_data.get('name', doc.id),
                'water_requirement_level': plant_data.get('water_requirement_level'),
                'drought_tolerance': plant_data.get('drought_tolerance'),
                'source': 'custom'
            })
    except Exception as e:
        print(f"Error loading custom plants: {e}")
    
    return plants
