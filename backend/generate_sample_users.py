"""
Generate Sample Users for WiEmpower System
Creates realistic farmer accounts with plants and data
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from utils.firebase_client import get_db
from services.plant_service import get_plant_features
from datetime import datetime
import random

# Sample data for Tunisia
TUNISIA_LOCATIONS = [
    "Zaghouan", "Tunis", "Sfax", "Sousse", "Kairouan", 
    "Bizerte", "Gabès", "Ariana", "Gafsa", "Monastir",
    "Ben Arous", "Kasserine", "Medenine", "Nabeul", "Tataouine"
]

TUNISIA_CROPS = [
    "tomato", "potato", "onion", "wheat", "barley",
    "olive", "date_palm", "citrus", "pepper", "eggplant",
    "cucumber", "melon", "watermelon", "grape", "almond"
]

SAMPLE_FARMERS = [
    {"name": "Mabrouka", "email": "mabrouka@farm.tn"},
    {"name": "Fatma", "email": "fatma@farm.tn"},
    {"name": "Aicha", "email": "aicha@farm.tn"},
    {"name": "Khadija", "email": "khadija@farm.tn"},
    {"name": "Zahra", "email": "zahra@farm.tn"},
    {"name": "Amina", "email": "amina@farm.tn"},
    {"name": "Salma", "email": "salma@farm.tn"},
    {"name": "Nadia", "email": "nadia@farm.tn"},
    {"name": "Leila", "email": "leila@farm.tn"},
    {"name": "Samira", "email": "samira@farm.tn"},
]

def generate_user_id(name, email):
    """Generate a unique user ID"""
    import hashlib
    hash_input = f"{name}_{email}_{datetime.now().timestamp()}"
    hash_value = hashlib.md5(hash_input.encode()).hexdigest()[:8]
    clean_name = name.lower().replace(" ", "_")
    return f"{clean_name}_{hash_value}"

def create_sample_user(farmer_data):
    """Create a single sample user with realistic data"""
    db = get_db()
    
    # Generate user ID
    user_id = generate_user_id(farmer_data["name"], farmer_data["email"])
    
    # Random location
    location = random.choice(TUNISIA_LOCATIONS)
    
    # Random soil properties
    soil_types = ["clay", "loam", "sandy", "silty"]
    soil_type_encoding = {"clay": 1, "loam": 2, "sandy": 3, "silty": 4}
    
    soil_type = random.choice(soil_types)
    soil_properties = {
        "soil_type": soil_type,
        "soil_type_encoded": soil_type_encoding[soil_type],
        "soil_compaction": random.randint(40, 70),
        "slope_degrees": round(random.uniform(0.5, 8.0), 1)
    }
    
    # Select 2-5 random crops
    num_crops = random.randint(2, 5)
    selected_crops = random.sample(TUNISIA_CROPS, num_crops)
    
    # Get plant features and create plants list
    plants = []
    for crop_name in selected_crops:
        features = get_plant_features(crop_name)
        if features:
            plant = {
                "name": crop_name,
                "area_sqm": random.randint(50, 500),
                "features": features
            }
            plants.append(plant)
    
    # Create user document
    user_data = {
        "user_id": user_id,
        "name": farmer_data["name"],
        "email": farmer_data["email"],
        "location": location,
        "soil_properties": soil_properties,
        "plants": plants,
        "ai_mode": True,
        "created_at": datetime.now().isoformat(),
        "watering_state": {
            "is_watering": False,
            "plant_name": None,
            "start_time": None,
            "expected_end": None,
            "mode": None
        }
    }
    
    # Save to Firestore
    db.collection('users').document(user_id).set(user_data)
    
    print(f"✅ Created user: {farmer_data['name']} ({user_id})")
    print(f"   Location: {location}")
    print(f"   Plants: {', '.join(selected_crops)}")
    print(f"   Email: {farmer_data['email']}")
    print()
    
    return user_id, user_data

def generate_all_users():
    """Generate all sample users"""
    print("🌱 GENERATING SAMPLE USERS FOR WIEEMPOWER")
    print("=" * 60)
    print()
    
    created_users = []
    
    for farmer in SAMPLE_FARMERS:
        try:
            user_id, user_data = create_sample_user(farmer)
            created_users.append({
                "user_id": user_id,
                "name": user_data["name"],
                "email": user_data["email"],
                "location": user_data["location"],
                "plants": [p["name"] for p in user_data["plants"]]
            })
        except Exception as e:
            print(f"❌ Error creating {farmer['name']}: {e}")
            print()
    
    print("=" * 60)
    print(f"✅ Successfully created {len(created_users)} users!")
    print()
    print("📋 SUMMARY:")
    print()
    for user in created_users:
        print(f"👤 {user['name']}")
        print(f"   ID: {user['user_id']}")
        print(f"   Email: {user['email']}")
        print(f"   Location: {user['location']}")
        print(f"   Plants: {', '.join(user['plants'])}")
        print()
    
    return created_users

if __name__ == "__main__":
    print()
    print("🇹🇳 Tunisia Women Farmers - Sample Data Generator")
    print()
    
    # Confirm before proceeding
    response = input("This will create 10 sample users in Firestore. Continue? (yes/no): ")
    
    if response.lower() in ['yes', 'y']:
        users = generate_all_users()
        
        print("=" * 60)
        print("🎉 DONE!")
        print()
        print("You can now:")
        print("1. Open admin.html and click 'تحديث القائمة' to see all users")
        print("2. Use any user_id in the mobile app")
        print("3. Add more plants to any user via admin interface")
        print()
    else:
        print("❌ Cancelled.")
