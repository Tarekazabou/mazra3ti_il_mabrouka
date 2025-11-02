# Quick Setup Guide - Linking Frontend (my_app) to Backend

This guide will help you quickly set up and test the connection between the Flutter frontend and Flask backend.

## Prerequisites

- Python 3.8+ installed
- Flutter SDK installed (for running the mobile app)
- Git (already installed if you cloned the repo)

## Step 1: Setup Backend

### 1.1 Install Python Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 1.2 Verify Firebase Credentials

Make sure the Firebase credentials file exists:
```bash
ls -la wieempower-b06dc-firebase-adminsdk-fbsvc-ffdf13ae17.json
```

### 1.3 Start the Backend Server

```bash
python app.py
```

You should see output like:
```
======================================================================
🌱 WIEEMPOWER - SMART IRRIGATION SYSTEM
   Supporting Women Farmers in Tunisia
======================================================================

📱 USER INTERFACE (Mobile App):
   GET  /api/farmer/<user_id>/state - Get farm state
   ...

 * Running on http://0.0.0.0:5000
```

### 1.4 Test Backend is Running

Open a new terminal and run:
```bash
curl http://localhost:5000/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "wieempower-backend",
  "version": "2.0"
}
```

## Step 2: Setup Frontend

### 2.1 Install Flutter Dependencies

```bash
cd my_app
flutter pub get
```

### 2.2 Configure Backend URL

Edit `my_app/lib/api_config.dart`:

For **Android Emulator**:
```dart
static const String baseUrl = 'http://10.0.2.2:5000';
```

For **iOS Simulator**:
```dart
static const String baseUrl = 'http://localhost:5000';
```

For **Physical Device** (on same network):
```dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:5000';
// Example: 'http://192.168.1.100:5000'
```

To find your computer's IP:
- **Windows**: `ipconfig` (look for IPv4 Address)
- **Mac/Linux**: `ifconfig` or `ip addr` (look for inet address)

### 2.3 Run the Flutter App

```bash
flutter run
```

## Step 3: Test the Integration

### Option A: Manual Testing via Code

Add this to your app (e.g., in a button's onPressed):

```dart
final farmModel = Provider.of<FarmModel>(context, listen: false);

// Test backend health
bool isHealthy = await farmModel.checkBackendHealth();
print('Backend health: $isHealthy');

if (isHealthy) {
  // Load farm state (replace with actual farmer ID)
  await farmModel.loadFarmStateFromApi('YOUR_FARMER_ID');
  print('Loaded farm state successfully!');
}
```

### Option B: Test Backend Endpoints Directly

Test individual endpoints with curl:

```bash
# Get farm state
curl http://localhost:5000/api/farmer/YOUR_FARMER_ID/state

# Get plants
curl http://localhost:5000/api/farmer/YOUR_FARMER_ID/plants

# Open valve
curl -X POST http://localhost:5000/api/farmer/YOUR_FARMER_ID/valve/open \
  -H "Content-Type: application/json" \
  -d '{"plant_name": "tomato", "duration_minutes": 30}'

# Close valve
curl -X POST http://localhost:5000/api/farmer/YOUR_FARMER_ID/valve/close
```

## Common Issues and Solutions

### Issue 1: "Connection refused" or "Failed to connect"

**Cause:** Backend not running or wrong URL

**Solution:**
1. Verify backend is running: `curl http://localhost:5000/health`
2. Check firewall isn't blocking port 5000
3. For Android emulator, use `10.0.2.2` instead of `localhost`
4. For physical device, use your computer's IP address

### Issue 2: "Module not found" when starting backend

**Cause:** Python dependencies not installed

**Solution:**
```bash
cd backend
pip install -r requirements.txt
```

### Issue 3: Flutter "Package not found" error

**Cause:** Flutter dependencies not installed

**Solution:**
```bash
cd my_app
flutter pub get
flutter clean
flutter pub get
```

### Issue 4: "Firebase credentials not found"

**Cause:** Missing Firebase service account file

**Solution:**
1. Make sure `wieempower-b06dc-firebase-adminsdk-fbsvc-ffdf13ae17.json` exists in `backend/` directory
2. If missing, download from Firebase Console > Project Settings > Service Accounts

### Issue 5: CORS errors in browser/app

**Cause:** CORS not properly configured (already handled, but just in case)

**Solution:**
Backend already has `flask-cors` configured. If issues persist:
1. Verify `flask-cors` is installed: `pip install flask-cors`
2. Backend `app.py` already has `CORS(app)` enabled

## Quick Reference

### Backend Commands
```bash
# Start backend
cd backend && python app.py

# Install dependencies
pip install -r requirements.txt

# Test health
curl http://localhost:5000/health
```

### Frontend Commands
```bash
# Install dependencies
cd my_app && flutter pub get

# Run on device/emulator
flutter run

# Run on specific device
flutter devices
flutter run -d <device_id>
```

### Key Files to Configure
1. **Backend URL**: `my_app/lib/api_config.dart`
2. **Backend Port**: `backend/app.py` (line 110: `port=5000`)
3. **Firebase Credentials**: `backend/wieempower-b06dc-firebase-adminsdk-fbsvc-ffdf13ae17.json`

## What's Been Connected?

✅ **Frontend (Flutter)** can now:
- Load farm state from backend API
- Control valves (open/close)
- Toggle AI automatic mode
- Get irrigation history
- Request AI irrigation decisions
- Check backend health

✅ **Backend (Flask)** provides:
- RESTful API endpoints
- Firebase integration
- AI irrigation decisions (XGBoost + Gemini)
- Weather forecasting
- Plant database management
- User and admin management

## Next Steps

1. **Add Authentication**: Implement user login to get farmer IDs automatically
2. **UI Integration**: Update UI widgets to use the new API methods
3. **Error Handling**: Add proper error messages in the UI
4. **Testing**: Test all features end-to-end
5. **Deployment**: Deploy backend to production server

## Documentation

- **Full Integration Guide**: `my_app/INTEGRATION_README.md`
- **Backend API Docs**: `backend/API_DOCUMENTATION.md`
- **Backend Structure**: `backend/BACKEND_STRUCTURE.md`

## Support

If you encounter any issues:
1. Check backend logs (terminal where `python app.py` is running)
2. Check Flutter logs (`flutter logs`)
3. Review the integration documentation
4. Test endpoints individually with curl
