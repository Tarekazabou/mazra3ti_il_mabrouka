# Firestore Data for Mazra3ti App

This directory contains pre-generated Firestore data for 10 sample farmers in Tunisia.

## Generated Files

1. **users_collection.json** - For backend API (20KB)
   - Contains detailed user data with plants, soil properties, location
   - Used by the Flask backend API endpoints

2. **farmers_collection.json** - For Flutter app (3.2KB)
   - Contains farmer basic info and vegetation list
   - Used by Flutter app's `firebase_service.dart`

3. **measurements_collection.json** - For Flutter app (3.2KB)
   - Contains sensor measurements (soil moisture, pump status, tank water, etc.)
   - Used by Flutter app's `farm_model.dart`

4. **summary.json** - Import summary (2.3KB)
   - Contains list of all generated users with their details

## Sample Users

| Name | User ID | Location | Plants |
|------|---------|----------|---------|
| Mabrouka | `mabrouka_1002dfc1` | Ben Arous | wheat, onion, melon |
| Fatma | `fatma_62165644` | Monastir | wheat, citrus, eggplant, barley, tomato |
| Aicha | `aicha_5204363a` | Nabeul | melon, citrus |
| Khadija | `khadija_4c319fe7` | Sousse | date_palm, barley |
| Zahra | `zahra_abe68881` | Tunis | citrus, date_palm, barley |
| Amina | `amina_657cdff1` | Tataouine | almond, cucumber, citrus, onion, barley |
| Salma | `salma_98736841` | Ariana | onion, cucumber |
| Nadia | `nadia_4d3fefd8` | Kairouan | watermelon, cucumber, olive, potato |
| Leila | `leila_01dcae1a` | Sousse | eggplant, olive |
| Samira | `samira_b3d81d2b` | Tunis | onion, cucumber, citrus |

## How to Import into Firestore

### Method 1: Using Firebase Console (Manual)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `wieempower-b06dc`
3. Navigate to Firestore Database
4. For each collection:
   - Click "Start collection"
   - Enter collection name: `users`, `farmers`, or `measurements`
   - Import documents from the corresponding JSON file

### Method 2: Using populate_firestore.py (Automatic - Requires Firebase Access)

```bash
cd backend
python3 populate_firestore.py
# Type 'yes' when prompted
```

This script will:
- Connect to Firebase using service account credentials
- Create all three collections automatically
- Populate them with the sample data

### Method 3: Using Firebase Admin SDK (Programmatic)

```python
from google.cloud import firestore
import json

db = firestore.Client()

# Import users collection
with open('firestore_data/users_collection.json', 'r') as f:
    users = json.load(f)
    for user_id, user_data in users.items():
        db.collection('users').document(user_id).set(user_data)

# Import farmers collection
with open('firestore_data/farmers_collection.json', 'r') as f:
    farmers = json.load(f)
    for user_id, farmer_data in farmers.items():
        db.collection('farmers').document(user_id).set(farmer_data)

# Import measurements collection
with open('firestore_data/measurements_collection.json', 'r') as f:
    measurements = json.load(f)
    for user_id, measurement_data in measurements.items():
        db.collection('measurements').document(user_id).set(measurement_data)

print("✅ Data imported successfully!")
```

## Data Structure

### Users Collection (Backend API)
```json
{
  "user_id": "mabrouka_1002dfc1",
  "name": "Mabrouka",
  "email": "mabrouka@farm.tn",
  "location": "Ben Arous",
  "soil_properties": {
    "soil_type": "loam",
    "soil_compaction": 55,
    "slope_degrees": 3.2
  },
  "plants": [
    {
      "name": "wheat",
      "area_sqm": 250,
      "features": { ... }
    }
  ],
  "ai_mode": true,
  "watering_state": { ... }
}
```

### Farmers Collection (Flutter App)
```json
{
  "farmerId": "mabrouka_1002dfc1",
  "name": "Mabrouka",
  "email": "mabrouka@farm.tn",
  "location": "Ben Arous",
  "vegetation": ["wheat", "onion", "melon"]
}
```

### Measurements Collection (Flutter App)
```json
{
  "farmerId": "mabrouka_1002dfc1",
  "soilMoisture": "moderate",
  "pumpStatus": "off",
  "tankWater": "half",
  "weatherAlert": "nothing",
  "controlMode": "automatic",
  "valveStatus": "closed",
  "temperature": 25.3,
  "humidity": 65.2
}
```

## Regenerating Data

To regenerate the data with different values:

```bash
cd backend
python3 generate_firestore_data.py
```

This will create new JSON files with:
- Random locations from Tunisia
- Random selection of 2-5 crops per farmer
- Random soil properties
- Random sensor measurements

## Testing with Flutter App

After importing the data:

1. Run the Flutter app
2. On the user selection screen, choose any of the 10 farmers
3. The app will load data from Firestore collections:
   - Farmer info from `farmers` collection
   - Measurements from `measurements` collection
4. Backend API will use data from `users` collection

## Notes

- All user IDs are consistently generated using MD5 hash
- Plant features are loaded from `tunisia_crops_full.json`
- Measurements include realistic random values for demos
- Data is compatible with both Flutter app and backend API
