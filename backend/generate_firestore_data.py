"""
Generate Firestore Data as JSON Files
Creates JSON files that can be imported into Firestore manually
Useful when direct Firebase connection is not available
"""

import json
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

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

# Load plant database for features
def load_plant_database():
    """Load plant features from tunisia_crops_full.json"""
    db_path = os.path.join(os.path.dirname(__file__), 'data', 'tunisia_crops_full.json')
    try:
        with open(db_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Warning: Could not load plant database: {e}")
        return {}

def get_plant_features(crop_name, plant_db):
    """Get plant features from database"""
    crop_name_lower = crop_name.lower().strip()
    
    # Check in database
    for crop_key, crop_data in plant_db.items():
        if crop_key.lower() == crop_name_lower or crop_data.get('name', '').lower() == crop_name_lower:
            return crop_data
    
    # Return default fallback
    return {
        'name': crop_name,
        'water_requirement_level': 3,
        'optimal_moisture_range': [50, 70],
        'critical_moisture_threshold': 30,
        'root_depth_cm': 50,
        'drought_tolerance': 3,
    }

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
    # Use fixed timestamp for consistent IDs
    hash_input = f"{name}_{email}_2024"
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

def generate_all_data():
    """Generate all Firestore data as JSON files"""
    print()
    print("="*70)
    print("🌱 GENERATING FIRESTORE DATA AS JSON FILES")
    print("   Supporting Women Farmers in Tunisia")
    print("="*70)
    print()
    
    # Load plant database
    plant_db = load_plant_database()
    print(f"Loaded {len(plant_db)} plants from database")
    print()
    
    # Collections to generate
    users_collection = {}
    farmers_collection = {}
    measurements_collection = {}
    
    created_users = []
    
    # Random seed for consistency
    random.seed(42)
    
    for farmer in SAMPLE_FARMERS:
        try:
            # Generate user ID
            user_id = generate_user_id(farmer["name"], farmer["email"])
            
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
                features = get_plant_features(crop_name, plant_db)
                plant = {
                    "name": crop_name,
                    "area_sqm": random.randint(50, 500),
                    "features": features
                }
                plants.append(plant)
            
            # 1. User document for 'users' collection (backend API)
            users_collection[user_id] = {
                "user_id": user_id,
                "name": farmer["name"],
                "email": farmer["email"],
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
            
            # 2. Farmer document for 'farmers' collection (Flutter app)
            farmers_collection[user_id] = {
                "farmerId": user_id,
                "name": farmer["name"],
                "email": farmer["email"],
                "location": location,
                "vegetation": selected_crops,
                "created_at": datetime.now().isoformat(),
                "vegetationUpdatedAt": datetime.now().isoformat(),
            }
            
            # 3. Measurements document for 'measurements' collection (Flutter app)
            measurements_data = generate_measurement_data()
            measurements_data["farmerId"] = user_id
            measurements_collection[user_id] = measurements_data
            
            created_users.append({
                "user_id": user_id,
                "name": farmer["name"],
                "email": farmer["email"],
                "location": location,
                "plants": selected_crops
            })
            
            print(f"✅ Generated data for: {farmer['name']} ({user_id})")
            print(f"   Location: {location}")
            print(f"   Plants: {', '.join(selected_crops)}")
            print()
            
        except Exception as e:
            print(f"❌ Error generating {farmer['name']}: {e}")
            import traceback
            traceback.print_exc()
            print()
    
    # Create output directory
    output_dir = os.path.join(os.path.dirname(__file__), 'firestore_data')
    os.makedirs(output_dir, exist_ok=True)
    
    # Save collections as JSON files
    with open(os.path.join(output_dir, 'users_collection.json'), 'w', encoding='utf-8') as f:
        json.dump(users_collection, f, indent=2, ensure_ascii=False)
    
    with open(os.path.join(output_dir, 'farmers_collection.json'), 'w', encoding='utf-8') as f:
        json.dump(farmers_collection, f, indent=2, ensure_ascii=False)
    
    with open(os.path.join(output_dir, 'measurements_collection.json'), 'w', encoding='utf-8') as f:
        json.dump(measurements_collection, f, indent=2, ensure_ascii=False)
    
    # Save summary
    summary = {
        "generated_at": datetime.now().isoformat(),
        "total_users": len(created_users),
        "users": created_users,
        "collections": {
            "users": len(users_collection),
            "farmers": len(farmers_collection),
            "measurements": len(measurements_collection)
        }
    }
    
    with open(os.path.join(output_dir, 'summary.json'), 'w', encoding='utf-8') as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)
    
    print("="*70)
    print(f"✅ Successfully generated data for {len(created_users)} users!")
    print()
    print(f"📁 Files saved to: {output_dir}/")
    print("   - users_collection.json (for backend API)")
    print("   - farmers_collection.json (for Flutter app)")
    print("   - measurements_collection.json (for Flutter app)")
    print("   - summary.json (import summary)")
    print()
    print("="*70)
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
    print("🎉 DATA GENERATION COMPLETE!")
    print()
    print("To import into Firestore:")
    print("1. Use Firebase Console's Import feature")
    print("2. Or use the populate_firestore.py script when Firebase is accessible")
    print("3. Or use Firebase Admin SDK with these JSON files")
    print()
    
    return created_users

if __name__ == "__main__":
    print()
    print("🇹🇳 Tunisia Women Farmers - Firestore Data Generator")
    print()
    
    users = generate_all_data()
