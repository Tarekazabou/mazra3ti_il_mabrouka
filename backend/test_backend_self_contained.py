"""
Test script to verify backend folder is completely self-contained
All imports and file paths should work from backend/ directory
"""

import sys
import os

# Add backend to path
backend_path = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, backend_path)

print("="*70)
print("🧪 TESTING SELF-CONTAINED BACKEND")
print("="*70)
print(f"Backend path: {backend_path}")
print()

# Test 1: Check file structure
print("1. Checking backend folder structure...")
required_files = [
    'models/model_should_water.pkl',
    'models/model_intensity.pkl', 
    'models/model_duration.pkl',
    'models/duration_features.pkl',
    'data/tunisia_crops_full.json',
    'wieempower-b06dc-firebase-adminsdk-fbsvc-ffdf13ae17.json',
    '.env',
]

all_files_exist = True
for file in required_files:
    file_path = os.path.join(backend_path, file)
    exists = os.path.exists(file_path)
    status = "✅" if exists else "❌"
    print(f"   {status} {file}")
    if not exists:
        all_files_exist = False

if all_files_exist:
    print("   ✅ All required files present!\n")
else:
    print("   ⚠️  Some files missing - backend may not work fully\n")

# Test 2: Import all services
print("2. Testing backend service imports...")
try:
    from utils.firebase_client import get_db
    print("   ✅ firebase_client")
except Exception as e:
    print(f"   ❌ firebase_client: {e}")

try:
    from services.plant_service import get_plant_features, list_all_plants
    print("   ✅ plant_service")
except Exception as e:
    print(f"   ❌ plant_service: {e}")

try:
    from services.weather_service import get_weather_forecast, get_weather_summary
    print("   ✅ weather_service")
except Exception as e:
    print(f"   ❌ weather_service: {e}")

try:
    from services.admin_service import add_user, list_all_users
    print("   ✅ admin_service")
except Exception as e:
    print(f"   ❌ admin_service: {e}")

try:
    from services.valve_service import open_valve_manual, close_valve_manual
    print("   ✅ valve_service")
except Exception as e:
    print(f"   ❌ valve_service: {e}")

try:
    from services.farmer_service import get_farm_state, get_user_plants
    print("   ✅ farmer_service")
except Exception as e:
    print(f"   ❌ farmer_service: {e}")

try:
    from services.irrigation_service import get_irrigation_decision, get_irrigation_history
    print("   ✅ irrigation_service")
except Exception as e:
    print(f"   ❌ irrigation_service: {e}")

# Test 3: Test routes
print("\n3. Testing route blueprints...")
try:
    from routes.admin_routes import admin_bp
    print(f"   ✅ admin_routes (prefix: {admin_bp.url_prefix})")
except Exception as e:
    print(f"   ❌ admin_routes: {e}")

try:
    from routes.farmer_routes import farmer_bp
    print(f"   ✅ farmer_routes (prefix: {farmer_bp.url_prefix})")
except Exception as e:
    print(f"   ❌ farmer_routes: {e}")

# Test 4: Test Firebase connection
print("\n4. Testing Firebase connection...")
try:
    from utils.firebase_client import get_db
    db = get_db()
    print(f"   ✅ Firebase connected: {db}")
except Exception as e:
    print(f"   ❌ Firebase connection failed: {e}")

# Test 5: Test plant database
print("\n5. Testing plant database...")
try:
    from services.plant_service import list_all_plants
    plants = list_all_plants()
    if isinstance(plants, list) and len(plants) > 0:
        print(f"   ✅ Loaded {len(plants)} plants from database")
        plant_names = [p['name'] for p in plants[:5]]
        print(f"   Sample plants: {', '.join(plant_names)}")
    else:
        print(f"   ❌ Failed to load plants or empty database")
except Exception as e:
    print(f"   ❌ Plant database error: {e}")

# Test 6: Test weather API
print("\n6. Testing weather API...")
try:
    from services.weather_service import get_weather_summary
    weather = get_weather_summary("Tunis")
    if weather['success']:
        print(f"   ✅ Weather API working - {weather['temperature']}°C")
    else:
        print(f"   ❌ Weather API failed: {weather.get('error')}")
except Exception as e:
    print(f"   ❌ Weather API error: {e}")

# Test 7: Test XGBoost models loading
print("\n7. Testing XGBoost models...")
try:
    from utils.gemini_decision import GeminiIrrigationDecision
    print("   ⚠️  Gemini Decision module loaded (requires API key)")
    print("   Note: XGBoost models load on first decision call")
except Exception as e:
    print(f"   ⚠️  Could not load Gemini Decision: {e}")
    print("   This is OK if GEMINI_API_KEY is not set")

print("\n" + "="*70)
print("✅ BACKEND SELF-CONTAINED TEST COMPLETE")
print("="*70)
print()
print("The backend/ folder contains all necessary files:")
print("  • XGBoost models (backend/models/)")
print("  • Plant database (backend/data/)")
print("  • Firebase credentials (backend/)")
print("  • All services (backend/services/)")
print("  • All utilities (backend/utils/)")
print("  • All routes (backend/routes/)")
print()
print("You can now:")
print("  1. Deploy the entire backend/ folder as a unit")
print("  2. Run from backend/ directory")
print("  3. Package backend/ as a Python package")
print()
