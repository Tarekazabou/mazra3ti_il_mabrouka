# Firestore Data Import Guide

This guide explains how to populate your Firestore database with sample data for the Mazra3ti Il Mabrouka Flutter app.

## 🎯 What This Does

The generated Firestore data provides:
- **10 sample farmers** from different regions of Tunisia
- **Realistic crop combinations** (wheat, tomato, olive, date palm, etc.)
- **Sensor measurements** (soil moisture, pump status, tank water, etc.)
- **Complete data structure** for both Flutter app and backend API

## 📁 Generated Files Location

All data files are in: `backend/firestore_data/`

- `users_collection.json` - Backend API data (20KB)
- `farmers_collection.json` - Flutter app farmer data (3.2KB)
- `measurements_collection.json` - Flutter app sensor data (3.2KB)
- `summary.json` - Import summary

## 🚀 Quick Start: Import Data to Firestore

### Option 1: Automatic Import (Recommended)

When you have Firebase access from your development environment:

```bash
cd backend
python3 populate_firestore.py
# Type 'yes' when prompted
```

This will automatically create and populate all three collections in Firestore.

### Option 2: Manual Import via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `wieempower-b06dc`
3. Navigate to **Firestore Database** in the left menu
4. Click **Start collection** or add to existing collection

For each collection (`users`, `farmers`, `measurements`):

#### Import users collection:
1. Click "Add collection"
2. Collection ID: `users`
3. For each user in `users_collection.json`:
   - Click "Add document"
   - Document ID: Use the key (e.g., `mabrouka_1002dfc1`)
   - Copy the entire JSON object as fields

#### Import farmers collection:
1. Click "Add collection"
2. Collection ID: `farmers`
3. For each farmer in `farmers_collection.json`:
   - Click "Add document"
   - Document ID: Use the key (e.g., `mabrouka_1002dfc1`)
   - Copy the entire JSON object as fields

#### Import measurements collection:
1. Click "Add collection"
2. Collection ID: `measurements`
3. For each measurement in `measurements_collection.json`:
   - Click "Add document"
   - Document ID: Use the key (e.g., `mabrouka_1002dfc1`)
   - Copy the entire JSON object as fields

### Option 3: Import using Python Script

Create a script to import the data programmatically:

```python
import json
from google.cloud import firestore

# Initialize Firestore
db = firestore.Client()

# Import users collection
print("Importing users collection...")
with open('backend/firestore_data/users_collection.json', 'r') as f:
    users = json.load(f)
    for user_id, user_data in users.items():
        db.collection('users').document(user_id).set(user_data)
        print(f"  ✓ Imported user: {user_id}")

# Import farmers collection
print("Importing farmers collection...")
with open('backend/firestore_data/farmers_collection.json', 'r') as f:
    farmers = json.load(f)
    for user_id, farmer_data in farmers.items():
        db.collection('farmers').document(user_id).set(farmer_data)
        print(f"  ✓ Imported farmer: {user_id}")

# Import measurements collection
print("Importing measurements collection...")
with open('backend/firestore_data/measurements_collection.json', 'r') as f:
    measurements = json.load(f)
    for user_id, measurement_data in measurements.items():
        db.collection('measurements').document(user_id).set(measurement_data)
        print(f"  ✓ Imported measurements: {user_id}")

print("\n✅ All data imported successfully!")
```

Save as `import_to_firestore.py` and run:
```bash
python3 import_to_firestore.py
```

## 📊 Sample Users

After import, these users will be available:

| Name | User ID | Location | Plants |
|------|---------|----------|---------|
| Mabrouka | mabrouka_1002dfc1 | Ben Arous | wheat, onion, melon |
| Fatma | fatma_62165644 | Monastir | wheat, citrus, eggplant, barley, tomato |
| Aicha | aicha_5204363a | Nabeul | melon, citrus |
| Khadija | khadija_4c319fe7 | Sousse | date_palm, barley |
| Zahra | zahra_abe68881 | Tunis | citrus, date_palm, barley |
| Amina | amina_657cdff1 | Tataouine | almond, cucumber, citrus, onion, barley |
| Salma | salma_98736841 | Ariana | onion, cucumber |
| Nadia | nadia_4d3fefd8 | Kairouan | watermelon, cucumber, olive, potato |
| Leila | leila_01dcae1a | Sousse | eggplant, olive |
| Samira | samira_b3d81d2b | Tunis | onion, cucumber, citrus |

## ✅ Verify Import

After importing, verify the data in Firebase Console:

1. Navigate to Firestore Database
2. You should see three collections:
   - `users` (10 documents)
   - `farmers` (10 documents)
   - `measurements` (10 documents)
3. Each collection should have documents with IDs matching the user IDs above

## 🧪 Testing with Flutter App

1. Run the Flutter app:
   ```bash
   cd my_app
   flutter run
   ```

2. On the user selection screen, you'll see all 10 farmers listed

3. Select any farmer to load their data from Firestore:
   - Farmer info comes from `farmers` collection
   - Sensor measurements come from `measurements` collection

4. The backend API uses data from `users` collection for AI decisions

## 🔄 Regenerate Data

To create new random data:

```bash
cd backend
python3 generate_firestore_data.py
```

This will regenerate all JSON files with:
- Different random locations
- Different random crops
- Different random sensor measurements

## 🏗️ Collections Structure

### users (Backend API)
```
users/
  mabrouka_1002dfc1/
    user_id: "mabrouka_1002dfc1"
    name: "Mabrouka"
    location: "Ben Arous"
    plants: [...]
    soil_properties: {...}
    ai_mode: true
    watering_state: {...}
```

### farmers (Flutter App)
```
farmers/
  mabrouka_1002dfc1/
    farmerId: "mabrouka_1002dfc1"
    name: "Mabrouka"
    location: "Ben Arous"
    vegetation: ["wheat", "onion", "melon"]
```

### measurements (Flutter App)
```
measurements/
  mabrouka_1002dfc1/
    farmerId: "mabrouka_1002dfc1"
    soilMoisture: "moderate"
    pumpStatus: "off"
    tankWater: "half"
    weatherAlert: "nothing"
    controlMode: "automatic"
    valveStatus: "closed"
```

## 🐛 Troubleshooting

### Firebase Connection Issues

If `populate_firestore.py` fails with DNS errors:
- Check your internet connection
- Verify Firebase service account credentials are in `backend/`
- Use manual import via Firebase Console instead

### Import Errors

If manual import fails:
- Ensure you're using the correct project in Firebase Console
- Verify the collection names are exactly: `users`, `farmers`, `measurements`
- Check that document IDs match between files

### App Not Loading Data

If the Flutter app doesn't show data:
1. Verify all three collections exist in Firestore
2. Check document IDs match the user IDs in `user_selection_screen.dart`
3. Ensure Firebase is properly initialized in the Flutter app
4. Check app logs for Firebase connection errors

## 📚 Additional Resources

- [Firebase Console](https://console.firebase.google.com/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- Backend README: `backend/BACKEND_README.md`
- Data files: `backend/firestore_data/`

## 💡 Tips

- **Backup before re-importing**: If you have existing data, back it up first
- **Use consistent IDs**: The user IDs in the Flutter app must match Firestore document IDs
- **Test with one user first**: Import one user's data to test before importing all
- **Check Firebase quotas**: Free tier has read/write limits

## 🎉 Success!

Once imported, you should be able to:
- ✅ Select any of the 10 farmers in the Flutter app
- ✅ See their vegetation and location
- ✅ View real-time measurements
- ✅ Use the backend API for AI irrigation decisions
- ✅ Test all app features with realistic data
