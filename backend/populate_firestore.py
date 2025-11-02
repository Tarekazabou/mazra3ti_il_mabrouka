"""
Populate Firestore with Sample Data
Creates data in both 'users' collection (for backend API) and 
'farmers'/'measurements' collections (for Flutter app direct access)
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

def generate_measurement_data():
    """Generate realistic measurement data"""
    soil_moistures = ["dry", "moderate", "wet"]
    pump_statuses = ["on", "off"]
    tank_waters = ["full", "half", "low"]
    weather_alerts = ["rainTomorrow", "veryHot", "nothing"]
    control_modes = ["manual", "automatic"]
    valve_statuses = ["open", "closed"]
    
    return {
        "soilMoisture": random.choice(soil_moistures),
        "pumpStatus": random.choice(pump_statuses),
        "tankWater": random.choice(tank_waters),
        "weatherAlert": random.choice(weather_alerts),
        "controlMode": random.choice(control_modes),
        "valveStatus": random.choice(valve_statuses),
        "lastUpdated": datetime.now().isoformat(),
        "temperature": round(random.uniform(15, 40), 1),
        "humidity": round(random.uniform(30, 90), 1),
    }

def create_sample_user(farmer_data):
    """Create a single sample user with realistic data in both collections"""
    db = get_db()
    
    # Generate user ID
    user_id = generate_user_id(farmer_data["name"], farmer_data["email"])
    
    # Random location
    location = random.choice(TUNISIA_LOCATIONS)
    
    # Random soil properties
    soil_types = ["clay", "loam", "sandy", "silty"]
    soil_properties = {
        "soil_type": random.choice(soil_types),
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
    
    # 1. Create user document in 'users' collection (for backend API)
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
    
    db.collection('users').document(user_id).set(user_data)
    print(f"✅ Created user in 'users' collection: {user_id}")
    
    # 2. Create farmer document in 'farmers' collection (for Flutter app)
    farmer_doc_data = {
        "farmerId": user_id,
        "name": farmer_data["name"],
        "email": farmer_data["email"],
        "location": location,
        "vegetation": selected_crops,  # List of plant names
        "created_at": datetime.now().isoformat(),
        "vegetationUpdatedAt": datetime.now().isoformat(),
    }
    
    db.collection('farmers').document(user_id).set(farmer_doc_data)
    print(f"✅ Created farmer in 'farmers' collection: {user_id}")
    
    # 3. Create measurements document in 'measurements' collection (for Flutter app)
    measurements_data = generate_measurement_data()
    measurements_data["farmerId"] = user_id
    
    db.collection('measurements').document(user_id).set(measurements_data)
    print(f"✅ Created measurements in 'measurements' collection: {user_id}")
    
    print(f"   📍 Location: {location}")
    print(f"   🌱 Plants: {', '.join(selected_crops)}")
    print(f"   📧 Email: {farmer_data['email']}")
    print()
    
    return user_id, user_data

def populate_firestore():
    """Populate Firestore with all sample users"""
    print()
    print("="*70)
    print("🌱 POPULATING FIRESTORE WITH SAMPLE DATA")
    print("   Supporting Women Farmers in Tunisia")
    print("="*70)
    print()
    print("This script will create data in:")
    print("  - 'users' collection (for backend API)")
    print("  - 'farmers' collection (for Flutter app)")
    print("  - 'measurements' collection (for Flutter app)")
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
            import traceback
            traceback.print_exc()
            print()
    
    print("="*70)
    print(f"✅ Successfully created {len(created_users)} users in Firestore!")
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
    
    print("="*70)
    print("🎉 FIRESTORE POPULATED!")
    print()
    print("You can now:")
    print("1. Run the Flutter app and select any user")
    print("2. The app will fetch data from 'farmers' and 'measurements' collections")
    print("3. Use the backend API with any user_id")
    print()
    
    return created_users

if __name__ == "__main__":
    print()
    print("🇹🇳 Tunisia Women Farmers - Firestore Data Population")
    print()
    
    # Confirm before proceeding
    response = input("This will populate Firestore with sample data. Continue? (yes/no): ")
    
    if response.lower() in ['yes', 'y']:
        users = populate_firestore()
    else:
        print("❌ Cancelled.")
