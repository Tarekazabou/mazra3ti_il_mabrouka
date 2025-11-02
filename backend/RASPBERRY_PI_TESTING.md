# Raspberry Pi Simulation & Testing

This folder contains scripts to simulate and test the complete irrigation system pipeline.

## 🍓 Raspberry Pi Simulation

### Overview

The **Raspberry Pi** is the hardware that:

1. Reads soil moisture from sensor (via ADC)
2. Sends data to backend server
3. Receives AI irrigation decision
4. Controls valve based on decision

### Test Scripts

#### 1. `simulate_raspberry_pi.py` - Full Simulation

Complete simulation of Raspberry Pi behavior with multiple test scenarios.

**Features:**

- Simulates soil moisture sensor readings
- Handles NEW users (first time) vs EXISTING users
- Tests continuous monitoring (multiple cycles)
- Shows complete decision flow
- Simulates valve activation

**Run:**

```bash
cd backend
python simulate_raspberry_pi.py
```

**Test Scenarios:**

1. **NEW USER** - First time using app

   - No watering history
   - `minutes_since_last_watering = 1440` (24 hours default)
   - Ensures ML model gets proper input

2. **EXISTING USER** - Has watering history

   - Calculates `minutes_since_last_watering` from last watering
   - Uses real data from Firebase

3. **CONTINUOUS MONITORING** - Multiple cycles
   - Simulates Pi checking every 30 minutes
   - Shows repeated decision cycles

**Output Example:**

```
🌱 IRRIGATION CYCLE STARTED
======================================================================

📊 Sensor Reading:
   Soil Moisture: 45.3%

⚠️  NEW USER - No watering history found
🆕 First-time user: Using 1440 minutes (24 hours) as default

📤 Sending to backend:
   URL: http://localhost:5000/api/farmer/test_user/decision
   Data: {
      "plant_name": "tomato",
      "soil_moisture": 45.3,
      "minutes_since_last_watering": 1440
   }

📥 Backend Response:
   Status Code: 200

🤖 AI DECISION:
   Should Water: true
   Duration: 25 minutes
   Intensity: 70%

💡 Reasoning:
   Soil moisture is below optimal range. Weather forecast shows minimal
   rain in next 24h. Watering recommended for plant health.

💧 VALVE ACTIVATED
   Duration: 25 minutes
   Intensity: 70%

🌦️  Weather Context:
   Temperature: 16.4°C
   Humidity: 65%
   Expected rain (24h): 2.3mm

✅ IRRIGATION CYCLE COMPLETE
```

#### 2. `quick_test_ml.py` - Quick ML Test

Simple, fast test of the ML decision pipeline.

**Run:**

```bash
cd backend
python quick_test_ml.py
```

**What it tests:**

- ✓ Backend connectivity
- ✓ Sensor data transmission
- ✓ ML model inference (XGBoost)
- ✓ Gemini AI refinement
- ✓ Weather API integration
- ✓ Complete decision flow

**Output Example:**

```
🧪 QUICK TEST - ML DECISION PIPELINE
======================================================================

📊 Test Configuration:
   User ID: test_user_123
   Plant: tomato
   Soil Moisture: 45.5%
   Minutes Since Last Watering: 1440 (NEW USER DEFAULT)

📤 Sending to backend...

📥 Response received!

✅ ML DECISION RESULT
======================================================================

🤖 AI Decision:
   Should Water: True
   Duration: 25 minutes
   Intensity: 70%

💡 Reasoning:
   XGBoost predicts watering needed. Gemini AI confirmed after analyzing
   weather forecast. Minimal rain expected (2.3mm).

🌦️  Weather Context:
   Temperature: 16.4°C
   Humidity: 65%
   Expected Rain (24h): 2.3mm

✅ TEST SUCCESSFUL - ML PIPELINE WORKING!

📊 ML Models Used:
   ✓ XGBoost - Should Water Model
   ✓ XGBoost - Duration Model
   ✓ XGBoost - Intensity Model
   ✓ Gemini AI - LLM Refinement
   ✓ Weather API - Forecast Data
```

## 🔑 NEW USER Handling

### Why 1440 minutes?

For **first-time users** (no watering history), the system uses:

```python
minutes_since_last_watering = 1440  # 24 hours
```

**Reasons:**

1. **ML Model Requirement** - Models were trained with this feature
2. **Safe Default** - 24 hours is reasonable time between waterings
3. **Prevents Errors** - Avoids `None` or `0` values
4. **Realistic** - Simulates normal watering schedule

### How it works in code:

```python
def get_minutes_since_last_watering(self):
    """
    Get minutes since last watering
    For NEW USERS: Return 1440 (24 hours) - large random number
    For EXISTING USERS: Calculate from last_watering timestamp
    """
    is_new = self.check_if_new_user()

    if is_new:
        # NEW USER: Use large random number
        minutes = 1440  # 24 hours
        return minutes

    # EXISTING USER: Get actual last watering time
    # Calculate from Firebase last_watering timestamp
    ...
```

## 🌐 Data Flow

```
Raspberry Pi (Sensor)
        ↓
  Read Soil Moisture (ADC)
        ↓
  Calculate minutes_since_last_watering
        • NEW USER: 1440 (default)
        • EXISTING: from last_watering
        ↓
  POST /api/farmer/<user_id>/decision
        {
          "plant_name": "tomato",
          "soil_moisture": 45.3,
          "minutes_since_last_watering": 1440
        }
        ↓
Backend Server (app.py)
        ↓
  farmer_routes.py → irrigation_service.py
        ↓
  1. Get user profile (soil properties, plants)
        ↓
  2. Call Weather API (forecast.py)
        ↓
  3. Run XGBoost Models (gemini_decision.py)
        • model_should_water.pkl
        • model_duration.pkl
        • model_intensity.pkl
        ↓
  4. Gemini AI Refinement
        • Analyzes weather
        • Refines XGBoost predictions
        • Considers water conservation
        ↓
  5. Return Decision
        {
          "success": true,
          "decision": {
            "should_water": true,
            "duration_minutes": 25,
            "intensity_percent": 70
          },
          "reasoning": "...",
          "weather": {...}
        }
        ↓
Raspberry Pi (Actuator)
        ↓
  Control Valve (GPIO)
        • Open valve
        • Set intensity (PWM)
        • Wait duration_minutes
        • Close valve
```

## 🎯 Testing Checklist

Before deploying to real Raspberry Pi:

- [ ] Backend server running (`python app.py`)
- [ ] Firebase connected (credentials loaded)
- [ ] Weather API working (key in `.env`)
- [ ] XGBoost models loaded (in `backend/models/`)
- [ ] Gemini API key configured (in `.env`)
- [ ] Run `quick_test_ml.py` - ML pipeline works
- [ ] Run `simulate_raspberry_pi.py` - Full simulation works
- [ ] Test NEW user scenario - 1440 min default working
- [ ] Test EXISTING user - calculated from history
- [ ] Test continuous monitoring - multiple cycles work

## 🔧 Real Raspberry Pi Implementation

### Hardware Setup

1. **Soil Moisture Sensor** → ADC (e.g., ADS1115) → Pi GPIO
2. **Valve Control** → Relay Module → Pi GPIO
3. **Internet Connection** → WiFi or Ethernet

### Software on Pi

```python
import RPi.GPIO as GPIO
import time
import requests
from ADS1115 import read_adc  # ADC library

# Configuration
BACKEND_URL = "http://your-server.com:5000"
USER_ID = "mabrouka_zaghouan"
PLANT_NAME = "tomato"
VALVE_PIN = 17  # GPIO pin for valve relay

# Read sensor
def read_soil_moisture():
    adc_value = read_adc(channel=0)
    moisture_percent = (adc_value / 32768.0) * 100
    return moisture_percent

# Get decision from backend
def get_decision(moisture):
    response = requests.post(
        f"{BACKEND_URL}/api/farmer/{USER_ID}/decision",
        json={
            'plant_name': PLANT_NAME,
            'soil_moisture': moisture,
            'minutes_since_last_watering': 1440  # Or calculate from history
        }
    )
    return response.json()

# Control valve
def activate_valve(duration_minutes):
    GPIO.output(VALVE_PIN, GPIO.HIGH)  # Open valve
    time.sleep(duration_minutes * 60)
    GPIO.output(VALVE_PIN, GPIO.LOW)   # Close valve

# Main loop
while True:
    moisture = read_soil_moisture()
    decision = get_decision(moisture)

    if decision['decision']['should_water']:
        duration = decision['decision']['duration_minutes']
        activate_valve(duration)

    time.sleep(30 * 60)  # Check every 30 minutes
```

## 📊 Expected Results

### NEW USER (First Time)

- `minutes_since_last_watering = 1440`
- ML models work correctly
- Decision returned successfully
- Valve activates if needed

### EXISTING USER (With History)

- `minutes_since_last_watering` calculated from Firebase
- Uses actual watering history
- More accurate predictions

### Continuous Monitoring

- System checks every 30 minutes
- Prevents overlapping waterings
- Tracks watering state in Firebase

## 🆘 Troubleshooting

### Backend not responding

```bash
# Check backend is running
cd backend
python app.py
```

### Connection refused

- Check `BACKEND_URL` is correct
- Ensure Pi and server on same network (or use public IP)
- Check firewall allows port 5000

### "User not found" error

- Create user first via admin interface:

```bash
curl -X POST http://localhost:5000/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","name":"Test","location":"Tunis",...}'
```

### ML models not loading

- Check `backend/models/` contains all `.pkl` files
- Check file permissions
- Verify `GEMINI_API_KEY` in `.env`

## 📚 Additional Resources

- **Backend API**: See `API_DOCUMENTATION.md`
- **Backend Structure**: See `BACKEND_STRUCTURE.md`
- **Setup Guide**: See `BACKEND_README.md`

---

**Ready to test the complete ML pipeline! 🚀**
