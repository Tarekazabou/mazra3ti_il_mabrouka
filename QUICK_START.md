# 🚀 Quick Start Guide - Mazra3ti Il Mabrouka

Get your app running with sample data in 3 easy steps!

## Step 1: Import Data to Firestore

Choose one of these methods:

### Method A: Automatic (When Firebase is accessible)
```bash
cd backend
python3 import_json_to_firestore.py
# Type 'yes' when prompted
```

### Method B: Direct Population (Alternative)
```bash
cd backend
python3 populate_firestore.py
# Type 'yes' when prompted
```

### Method C: Manual via Firebase Console
See detailed instructions in [FIRESTORE_IMPORT_GUIDE.md](FIRESTORE_IMPORT_GUIDE.md)

## Step 2: Run the Backend API

```bash
cd backend
python3 app.py
```

The backend will start on `http://localhost:5000`

## Step 3: Run the Flutter App

```bash
cd my_app
flutter run
```

## 🎉 You're Ready!

The app will show 10 sample farmers. Select any one to see their farm data!

### Available Farmers

1. **Mabrouka** (Ben Arous) - wheat, onion, melon
2. **Fatma** (Monastir) - wheat, citrus, eggplant, barley, tomato
3. **Aicha** (Nabeul) - melon, citrus
4. **Khadija** (Sousse) - date palm, barley
5. **Zahra** (Tunis) - citrus, date palm, barley
6. **Amina** (Tataouine) - almond, cucumber, citrus, onion, barley
7. **Salma** (Ariana) - onion, cucumber
8. **Nadia** (Kairouan) - watermelon, cucumber, olive, potato
9. **Leila** (Sousse) - eggplant, olive
10. **Samira** (Tunis) - onion, cucumber, citrus

## 📊 What Data is Available?

Each farmer has:
- ✅ **Personal Info**: Name, location, email
- ✅ **Crops**: 2-5 different plants
- ✅ **Soil Data**: Type, compaction, slope
- ✅ **Measurements**: Soil moisture, pump status, tank level
- ✅ **Weather**: Alerts and forecasts
- ✅ **Controls**: Manual/Automatic mode, valve status

## 🔧 Troubleshooting

### "No data found"
- Verify Firestore collections exist: `users`, `farmers`, `measurements`
- Check Firebase connection in the app
- Run import script again

### "Backend not responding"
- Make sure backend is running on port 5000
- Check `backend/app.py` is running
- Verify API config in `my_app/lib/api_config.dart`

### "Firebase connection error"
- Check Firebase credentials in `backend/wieempower-*.json`
- Verify Firebase is initialized in Flutter app
- Check internet connection

## 📚 More Information

- [FIRESTORE_IMPORT_GUIDE.md](FIRESTORE_IMPORT_GUIDE.md) - Detailed import instructions
- [backend/BACKEND_README.md](backend/BACKEND_README.md) - Backend documentation
- [backend/firestore_data/README.md](backend/firestore_data/README.md) - Data structure details

## 💡 Tips

- Use **Mabrouka** (mabrouka_1002dfc1) for testing - she has a balanced crop mix
- Check Firebase Console to see real-time data updates
- The backend API provides AI irrigation recommendations
- All sensor data updates in real-time via Firestore

## 🎯 What's Next?

After getting the app running:
1. Test the AI irrigation recommendations
2. Try manual valve control
3. View irrigation history
4. Add more farmers or crops
5. Customize the data for your needs

---

**Need Help?** Check the detailed guides or contact the development team.
