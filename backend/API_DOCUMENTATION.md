# 🌱 WiEmpower Backend API Documentation

## Overview

The WiEmpower backend is a modular Flask application for smart irrigation decisions supporting women farmers in Tunisia. It has two main interfaces:

1. **Farmer Interface** - For women farmers (like Mabrouka) via mobile app
2. **Admin Interface** - For administrators to manage users and system

## Architecture

```
app_new.py (Main orchestrator)
    ↓
backend/
    ├── routes/
    │   ├── farmer_routes.py    # Farmer mobile endpoints
    │   └── admin_routes.py     # Admin management endpoints
    ├── services/
    │   ├── farmer_service.py   # Farm state logic
    │   ├── admin_service.py    # User CRUD logic
    │   ├── irrigation_service.py # AI decision engine
    │   ├── valve_service.py    # Manual valve control
    │   ├── weather_service.py  # Weather forecasting
    │   └── plant_service.py    # Plant database + Gemini generation
    └── utils/
        └── firebase_client.py  # Firebase singleton
```

All business logic is in `backend/`. The main `app_new.py` only imports routes and registers blueprints.

---

## 📱 Farmer Interface (Mobile App)

### Base URL: `/api/farmer`

These endpoints power the women farmers' mobile interface.

---

### GET `/api/farmer/<user_id>/state`

**Get complete farm state for mobile app home screen**

Shows everything the farmer needs to see:

- Name, location, plants
- Current watering status (is valve open?)
- Weather summary
- AI mode status
- Recent activity

**Response:**

```json
{
  "success": true,
  "user": {
    "name": "Mabrouka",
    "location": "Zaghouan",
    "email": "mabrouka@farm.tn"
  },
  "plants": [
    {"name": "tomato", "area_sqm": 100},
    {"name": "olive", "area_sqm": 500}
  ],
  "valve": {
    "is_watering": true,
    "remaining_minutes": 15,
    "plant_name": "tomato",
    "mode": "ai"
  },
  "ai_mode": true,
  "weather": {
    "temperature": 28.5,
    "humidity": 55,
    "condition": "Partly cloudy",
    "total_rain_24h": 2.5,
    "max_rain_probability": 30
  },
  "last_watering": "2025-11-02T10:30:00",
  "recent_activity": [...]
}
```

---

### POST `/api/farmer/<user_id>/valve/open`

**Manually open valve (farmer override)**

When the farmer wants to water manually instead of waiting for AI.

**Body:**

```json
{
  "plant_name": "tomato",
  "duration_minutes": 30
}
```

**Response:**

```json
{
  "success": true,
  "message": "Valve opened manually for 30 minutes",
  "watering_state": {
    "is_watering": true,
    "plant_name": "tomato",
    "start_time": "2025-11-02T11:00:00",
    "expected_end": "2025-11-02T11:30:00",
    "mode": "manual"
  }
}
```

---

### POST `/api/farmer/<user_id>/valve/close`

**Manually close valve (farmer override)**

Stop watering immediately.

**Response:**

```json
{
  "success": true,
  "message": "Valve closed manually, watering stopped"
}
```

---

### GET `/api/farmer/<user_id>/valve/status`

**Get current valve status**

Check if valve is open and how much time is remaining.

**Response:**

```json
{
  "success": true,
  "is_watering": true,
  "remaining_minutes": 15,
  "plant_name": "tomato",
  "watering_mode": "ai",
  "ai_mode": true,
  "last_watering": "2025-11-02T10:30:00"
}
```

---

### POST `/api/farmer/<user_id>/ai-mode`

**Toggle AI automatic mode on/off**

Let the farmer choose: AI makes decisions OR manual control only.

**Body:**

```json
{
  "ai_mode": true // or false
}
```

**Response:**

```json
{
  "success": true,
  "ai_mode": true,
  "message": "AI automatic mode enabled"
}
```

---

### POST `/api/farmer/<user_id>/decision`

**Get AI irrigation decision**

Called by:

- Half-hourly scheduler (automatic)
- Farmer clicking "Check now" button
- Sensor triggers

**Body:**

```json
{
  "plant_name": "tomato",
  "soil_moisture": 45.5,
  "sensor_temperature": 28.3, // optional
  "sensor_humidity": 52.1 // optional
}
```

**Response:**

```json
{
  "success": true,
  "decision": {
    "should_water": true,
    "duration_minutes": 35,
    "intensity_percent": 70,
    "confidence": 0.92
  },
  "reasoning": "Soil moisture at 45.5% is below optimal range...",
  "weather": {
    "current": { "temperature": 28.3, "humidity": 52.1 },
    "total_rain_24h": 2.5,
    "max_rain_probability": 25
  }
}
```

**Special Response (watering in progress):**

```json
{
  "success": true,
  "watering_in_progress": true,
  "remaining_minutes": 15,
  "message": "Watering already in progress for 'tomato'."
}
```

---

### GET `/api/farmer/<user_id>/history`

**Get irrigation history**

Show past decisions and actions.

**Query params:**

- `limit` (optional, default 50)

**Response:**

```json
{
  "success": true,
  "count": 10,
  "logs": [
    {
      "timestamp": "2025-11-02T10:30:00",
      "plant_name": "tomato",
      "action": "decision",
      "decision": {...},
      "reasoning": "..."
    }
  ]
}
```

---

## 👨‍💼 Admin Interface

### Base URL: `/api/admin`

These endpoints are for administrators to manage the system.

---

### GET `/api/admin/users`

**List all users**

**Query params:**

- `role` (optional): Filter by role (`farmer`, `admin`)

**Response:**

```json
{
  "success": true,
  "count": 5,
  "users": [
    {
      "user_id": "user123",
      "name": "Mabrouka",
      "email": "mabrouka@farm.tn",
      "location": "Zaghouan",
      "plants": [{ "name": "tomato", "area_sqm": 100 }],
      "ai_mode": true,
      "created_at": "2025-11-01T10:00:00"
    }
  ]
}
```

---

### POST `/api/admin/users`

**Add new user**

Create a new farmer profile with soil properties and plants.

**Body:**

```json
{
  "email": "mabrouka@farm.tn",
  "name": "Mabrouka",
  "location": "Zaghouan",
  "soil_properties": {
    "soil_type": "loam", // sandy, loam, or clay
    "soil_compaction": 55, // 0-100
    "slope_degrees": 3.5 // 0-45
  },
  "plants": [
    { "name": "tomato", "area_sqm": 100 },
    { "name": "olive", "area_sqm": 500 }
  ]
}
```

**Response:**

```json
{
  "success": true,
  "user_id": "abc123",
  "message": "User Mabrouka added successfully",
  "plants_processed": 2
}
```

**Note:** If a plant is not in the database, the system automatically generates features using Gemini AI!

---

### GET `/api/admin/users/<user_id>`

**Get user details**

Full profile including plant features.

**Response:**

```json
{
  "success": true,
  "user": {
    "user_id": "abc123",
    "name": "Mabrouka",
    "email": "mabrouka@farm.tn",
    "location": "Zaghouan",
    "soil_properties": {...},
    "plants": [...],
    "ai_mode": true,
    "last_watering": "2025-11-02T10:30:00",
    "created_at": "2025-11-01T10:00:00"
  }
}
```

---

### PUT `/api/admin/users/<user_id>`

**Update user details**

Modify any user fields.

**Body:** (fields to update)

```json
{
  "location": "Tunis",
  "soil_properties": {
    "soil_type": "clay",
    "soil_compaction": 60,
    "slope_degrees": 5
  }
}
```

**Response:**

```json
{
  "success": true,
  "message": "User abc123 updated successfully"
}
```

---

### DELETE `/api/admin/users/<user_id>`

**Delete user**

Remove user from system.

**Response:**

```json
{
  "success": true,
  "message": "User abc123 deleted successfully"
}
```

---

### POST `/api/admin/users/<user_id>/plants`

**Add plant to user**

Add a new crop to the farmer's profile.

**Body:**

```json
{
  "name": "pepper",
  "area_sqm": 50
}
```

**Response:**

```json
{
  "success": true,
  "plant": {
    "name": "pepper",
    "area_sqm": 50,
    "features": {
      "water_requirement_level": 4,
      "optimal_moisture_range": [60, 75],
      "critical_moisture_threshold": 35,
      "root_depth_cm": 45,
      "drought_tolerance": 2
    }
  },
  "message": "Plant pepper added to user abc123"
}
```

---

### DELETE `/api/admin/users/<user_id>/plants/<plant_name>`

**Remove plant from user**

**Response:**

```json
{
  "success": true,
  "message": "Plant tomato removed from user abc123"
}
```

---

### GET `/api/admin/plants`

**List all available plants**

Shows all plants in the database (Tunisia crops + custom generated).

**Response:**

```json
{
  "success": true,
  "count": 35,
  "plants": [
    {
      "id": "tomato",
      "name": "Tomato",
      "water_requirement_level": 4,
      "drought_tolerance": 2,
      "source": "database"
    },
    {
      "id": "strawberry",
      "name": "Strawberry",
      "water_requirement_level": 5,
      "drought_tolerance": 1,
      "source": "custom"
    }
  ]
}
```

---

### GET `/api/admin/stats`

**Get system statistics**

Overview of the entire system.

**Response:**

```json
{
  "success": true,
  "stats": {
    "total_users": 25,
    "active_ai_users": 20,
    "total_plants": 75,
    "timestamp": "2025-11-01T10:00:00"
  }
}
```

---

## 🛠️ System Endpoints

### GET `/`

**API documentation**

Returns complete endpoint list.

---

### GET `/health`

**Health check**

Check if system is running and models are loaded.

**Response:**

```json
{
  "status": "healthy",
  "timestamp": "2025-11-02T11:00:00",
  "models_loaded": true,
  "gemini_available": true,
  "version": "1.0.0"
}
```

---

## 🔄 Typical Workflows

### Workflow 1: Admin adds new farmer (Mabrouka)

```bash
# 1. Admin adds Mabrouka to system
POST /api/admin/users
{
  "email": "mabrouka@farm.tn",
  "name": "Mabrouka",
  "location": "Zaghouan",
  "soil_properties": {...},
  "plants": [{"name": "tomato", "area_sqm": 100}]
}

# Response: user_id = "mabrouka123"
```

### Workflow 2: Mabrouka checks her farm (mobile app)

```bash
# Mobile app loads farm state
GET /api/farmer/mabrouka123/state

# Shows:
# - Her plants
# - Valve status
# - Weather
# - AI mode enabled
```

### Workflow 3: Automatic irrigation decision (every 30 minutes)

```bash
# Scheduler calls decision endpoint
POST /api/farmer/mabrouka123/decision
{
  "plant_name": "tomato",
  "soil_moisture": 45.5
}

# System:
# 1. Checks if already watering → returns remaining time if yes
# 2. Gets weather forecast
# 3. Runs XGBoost + Gemini AI
# 4. Returns decision + reasoning
# 5. If should_water=true, sets watering_state in Firebase
```

### Workflow 4: Mabrouka wants to water manually

```bash
# She taps "Water Now" button in mobile app
POST /api/farmer/mabrouka123/valve/open
{
  "plant_name": "tomato",
  "duration_minutes": 30
}

# Valve opens for 30 minutes
# System logs it as "manual" mode
```

### Workflow 5: Mabrouka disables AI mode

```bash
# She toggles AI mode off
POST /api/farmer/mabrouka123/ai-mode
{
  "ai_mode": false
}

# Now AI won't make automatic decisions
# Only manual valve control allowed
```

---

## 🚀 Running the Server

```bash
# Start server
python app_new.py
```

Server runs on: `http://0.0.0.0:5000`

---

## 📂 File Structure

```
backend/
├── routes/
│   ├── farmer_routes.py     # Farmer mobile endpoints
│   └── admin_routes.py      # Admin management endpoints
├── services/
│   ├── farmer_service.py    # get_farm_state, get_user_plants
│   ├── admin_service.py     # add_user, update_user, delete_user, etc.
│   ├── irrigation_service.py # get_irrigation_decision
│   ├── valve_service.py     # open_valve_manual, close_valve_manual, set_ai_mode
│   ├── weather_service.py   # get_weather_forecast
│   └── plant_service.py     # get_plant_features (with Gemini generation)
└── utils/
    └── firebase_client.py   # Firebase singleton
```

All business logic is separated by concern!

---

## ✅ Key Features

1. **Separated concerns**: Each service has one clear responsibility
2. **AI mode toggle**: Farmer can choose AI or manual control
3. **Manual override**: Farmer can always open/close valve manually
4. **Auto plant generation**: Unknown plants get features from Gemini AI
5. **Watering state tracking**: Prevents overlapping irrigation runs
6. **Half-hourly checks**: Scheduler can safely call decision endpoint
7. **Complete logging**: All actions logged to Firebase

---

**Built for women farmers in Tunisia 🇹🇳 🌱**
