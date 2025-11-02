# Backend Folder - Complete Structure

## ✅ Self-Contained Backend

The `backend/` folder now contains **everything** needed to run the application backend. You can deploy just this folder anywhere!

## 📁 Complete File Tree

```
backend/
│
├── app.py                          # 🚀 Main Flask application (run this!)
├── .env                            # 🔑 Environment variables (API keys)
├── models_metadata.json            # 📊 Model training metadata
├── wieempower-...-firebase-adminsdk-....json  # 🔥 Firebase credentials
│
├── models/                         # 🤖 XGBoost trained models
│   ├── model_should_water.pkl      # Decision: should water? (classification)
│   ├── model_intensity.pkl         # Water intensity % (regression)
│   ├── model_duration.pkl          # Watering duration minutes (regression)
│   └── duration_features.pkl       # Feature names for duration model
│
├── data/                           # 🌾 Plant database
│   └── tunisia_crops_full.json     # 30 Tunisia crops with features
│
├── services/                       # 💼 Business logic (each mission separated)
│   ├── admin_service.py            # User management (CRUD operations)
│   ├── farmer_service.py           # Farm state for mobile app
│   ├── irrigation_service.py       # AI decision making (XGBoost + Gemini)
│   ├── valve_service.py            # Manual valve control + AI mode toggle
│   ├── weather_service.py          # Weather forecast wrapper
│   └── plant_service.py            # Plant features + Gemini generation
│
├── routes/                         # 🛣️ HTTP endpoints
│   ├── admin_routes.py             # Admin interface endpoints (/api/admin/*)
│   └── farmer_routes.py            # Farmer interface endpoints (/api/farmer/<user_id>/*)
│
├── utils/                          # 🔧 Shared utilities
│   ├── firebase_client.py          # Firebase singleton client
│   ├── forecast.py                 # Weather API integration (WeatherAPI.com)
│   └── gemini_decision.py          # Gemini LLM decision layer
│
├── test_backend_self_contained.py  # ✅ Test script (verifies everything works)
├── BACKEND_README.md               # 📖 Quick start guide
├── API_DOCUMENTATION.md            # 📚 Complete API reference
├── README.md                       # 📋 Setup and architecture
└── __init__.py                     # 📦 Python package marker
```

## 🎯 What's Inside Each Folder

### `/models/` - XGBoost Trained Models

- **model_should_water.pkl**: Binary classifier → Should water? (True/False)
- **model_intensity.pkl**: Regression → Water intensity (20-100%)
- **model_duration.pkl**: Regression → Duration (5-90 minutes)
- **duration_features.pkl**: Feature column names for duration prediction

All trained on Tunisia-specific irrigation data with:

- Soil properties (type, compaction, slope)
- Plant characteristics (water needs, root depth, drought tolerance)
- Environmental conditions (moisture, temperature, humidity)
- Time factors (season, hour of day, minutes since last watering)

### `/data/` - Plant Database

- **tunisia_crops_full.json**: 30 crops including:
  - Cereals: Durum wheat, soft wheat, barley
  - Vegetables: Tomato, potato, pepper, eggplant
  - Fruits: Olive, citrus, date palm, fig
  - Fodder: Alfalfa, oats, clover
  - Each with 11+ features (water needs, root depth, drought tolerance, etc.)

### `/services/` - Business Logic (Separated by Mission)

**admin_service.py** - User Management

- `add_user()` - Create new user with soil properties and plants
- `update_user()` - Modify user details
- `delete_user()` - Remove user
- `get_user()` - Retrieve user details
- `list_all_users()` - Get all users
- `add_plant_to_user()` - Assign plant to user
- `remove_plant_from_user()` - Remove plant

**farmer_service.py** - Farmer Mobile Interface

- `get_farm_state()` - Complete farm view (plants, weather, valve, AI mode)
- `get_user_plants()` - User's plant list

**irrigation_service.py** - AI Decision Engine

- `get_irrigation_decision()` - XGBoost + Gemini LLM decision
  1. Checks watering_state (prevents overlaps)
  2. Gets weather forecast (rain probability)
  3. XGBoost predicts: should_water, duration, intensity
  4. Gemini refines with weather context
  5. Updates watering_state if decision is to water
  6. Logs decision to Firebase
- `get_irrigation_history()` - Past decisions
- `calculate_season()` - Season from day of year

**valve_service.py** - Valve Control

- `open_valve_manual()` - Farmer opens valve (sets watering_state)
- `close_valve_manual()` - Farmer closes valve (clears watering_state)
- `set_ai_mode()` - Enable/disable AI automatic control
- `get_valve_status()` - Current valve state

**weather_service.py** - Weather Integration

- `get_weather_forecast()` - 24-hour hourly forecast
- `get_weather_summary()` - Simplified for mobile display

**plant_service.py** - Plant Features

- `get_plant_features()` - Plant characteristics
  1. Checks local JSON database
  2. Checks Firebase cache
  3. Generates with Gemini AI if not found
  4. Caches in Firebase for future use
- `list_all_plants()` - All available plants

### `/routes/` - HTTP Endpoints

**admin_routes.py** - Admin Interface Blueprint

```
GET    /api/admin/users              - List all users
POST   /api/admin/users              - Add new user
GET    /api/admin/users/<id>         - Get user details
PUT    /api/admin/users/<id>         - Update user
DELETE /api/admin/users/<id>         - Delete user
POST   /api/admin/users/<id>/plants  - Add plant to user
DELETE /api/admin/users/<id>/plants/<name> - Remove plant
GET    /api/admin/plants             - List all plants
GET    /api/admin/stats              - System statistics
```

**farmer_routes.py** - Farmer Interface Blueprint

```
GET  /api/farmer/<user_id>/state         - Get farm state
POST /api/farmer/<user_id>/valve/open   - Open valve manually
POST /api/farmer/<user_id>/valve/close  - Close valve
GET  /api/farmer/<user_id>/valve/status - Valve status
POST /api/farmer/<user_id>/ai-mode      - Toggle AI mode
POST /api/farmer/<user_id>/decision     - Get AI decision
GET  /api/farmer/<user_id>/history      - Irrigation history
GET  /api/farmer/<user_id>/plants       - User's plants
```

### `/utils/` - Shared Utilities

**firebase_client.py** - Firebase Singleton

- `get_db()` - Returns Firestore client instance
- Loads credentials from `wieempower-...-firebase-adminsdk-....json`
- Initializes Firebase app once (singleton pattern)

**forecast.py** - Weather API Wrapper

- `get_weather_forecast(location)` - Gets 24-hour forecast
  - Current: temperature, humidity, condition, wind
  - Hourly: rain probability (0-100%), precipitation (mm)
  - Returns total rainfall 24h
- Uses WeatherAPI.com (key in .env)

**gemini_decision.py** - Gemini LLM Decision Layer

- `GeminiIrrigationDecision` class
  - Loads XGBoost models from `/models/`
  - `decide()` - Main decision function:
    1. XGBoost predictions (Stage 1)
    2. Weather forecast analysis
    3. Gemini LLM reasoning (Stage 2)
    4. Final decision with water conservation
  - Fallback to rule-based if API fails
- Uses Google Gemini 2.0 Flash model

## 🔄 Data Flow

### Farmer Opens Valve Manually

```
Mobile App
    ↓ POST /api/farmer/<user_id>/valve/open
farmer_routes.py
    ↓ calls
valve_service.open_valve_manual()
    ↓ updates
Firebase: watering_state = {is_watering: true, start_time, expected_end, mode: "manual"}
    ↓ logs
Firebase: irrigation_logs (action: "manual_open")
```

### Half-Hourly AI Decision

```
Scheduler (every 30 min)
    ↓ POST /api/farmer/<user_id>/decision
farmer_routes.py
    ↓ calls
irrigation_service.get_irrigation_decision()
    ↓ checks
watering_state (if watering → return remaining_minutes)
    ↓ gets
weather_service.get_weather_forecast()
    ↓ calls
gemini_decision.decide()
    ↓ Stage 1: XGBoost
    - should_water? (model_should_water.pkl)
    - duration? (model_duration.pkl)
    - intensity? (model_intensity.pkl)
    ↓ Stage 2: Gemini LLM
    - Analyzes weather (rain coming?)
    - Refines XGBoost decision
    - Considers water conservation
    ↓ if should_water:
Firebase: watering_state = {is_watering: true, mode: "ai"}
Firebase: irrigation_logs (decision + reasoning)
```

### Admin Adds User

```
Admin Dashboard
    ↓ POST /api/admin/users
admin_routes.py
    ↓ calls
admin_service.add_user()
    ↓ for each plant:
plant_service.get_plant_features()
    ↓ checks
tunisia_crops_full.json → Firebase cache → Gemini generation
    ↓ creates
Firebase: users/{user_id} = {name, location, soil_properties, plants, ai_mode: true}
```

## 🚀 Running the Backend

### Quick Start

```bash
cd backend
python app.py
```

Server runs on `http://0.0.0.0:5000`

### Test Everything

```bash
cd backend
python test_backend_self_contained.py
```

Expected output:

```
✅ All required files present!
✅ All services import correctly
✅ Firebase connected
✅ Loaded 30 plants from database
✅ Weather API working - 16.4°C
```

### Test API Endpoints

```bash
# Health check
curl http://localhost:5000/health

# Root (API documentation)
curl http://localhost:5000/

# Admin: List users
curl http://localhost:5000/api/admin/users

# Farmer: Get farm state (replace USER_ID)
curl http://localhost:5000/api/farmer/USER_ID/state
```

## 📦 Dependencies

All in parent `requirements.txt`:

```
flask>=2.3.0
flask-cors>=4.0.0
firebase-admin>=6.2.0
requests>=2.31.0
google-generativeai>=0.3.0
xgboost>=2.0.0
joblib>=1.3.0
pandas>=2.0.0
numpy>=1.24.0
python-dotenv>=1.0.0
```

## 🔑 Environment Variables

In `.env`:

```bash
GEMINI_API_KEY=your-gemini-api-key
WEATHER_API_KEY=your-weather-api-key
```

## 🎯 Key Features

1. **Completely Self-Contained**

   - All models, data, and code in one folder
   - No dependencies on parent directory
   - Deploy as single unit

2. **Modular Architecture**

   - Each mission in separate file (as specified)
   - Clear separation of concerns
   - Easy to maintain and extend

3. **Two-Part Application**

   - Farmer interface (mobile app)
   - Admin interface (web dashboard)

4. **Smart AI Decisions**

   - XGBoost models trained on Tunisia data
   - Gemini LLM refines with weather context
   - Water conservation without compromising plant health

5. **Safety Features**
   - Watering state prevents overlaps
   - Manual override always available
   - AI mode can be disabled per user

## 🌍 Production Ready

The backend/ folder can be:

- Deployed to any cloud platform (Heroku, Railway, AWS, etc.)
- Containerized with Docker
- Run on VPS with nginx + gunicorn
- Packaged as Python package

Just copy the entire folder and run!

---

**✅ Backend is completely self-contained and production-ready!**
