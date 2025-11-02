# Frontend-Backend Integration Guide

This document explains how the Flutter app (my_app) connects to the Flask backend.

## Overview

The frontend has been integrated with the backend API. The app now supports both:
1. **Firebase** - For real-time data synchronization (original functionality)
2. **Backend API** - For advanced features like AI irrigation decisions, valve control, and more

## Architecture

```
my_app (Flutter Frontend)
    ↓
    ├── Firebase (Real-time data)
    └── Backend API (REST endpoints at localhost:5000)
            ↓
        Flask Backend (Python)
```

## Files Added/Modified

### New Files:
1. **`lib/api_service.dart`** - Service class for backend API communication
2. **`lib/api_config.dart`** - Configuration file for API endpoints
3. **`INTEGRATION_README.md`** - This documentation

### Modified Files:
1. **`pubspec.yaml`** - Added `http: ^1.1.0` dependency
2. **`lib/farm_model.dart`** - Added backend API methods alongside Firebase methods
3. **`lib/main.dart`** - Updated comments to show both Firebase and API usage

## Configuration

### Setting the Backend URL

Edit `lib/api_config.dart` to configure the backend URL based on your environment:

```dart
class ApiConfig {
  static const String baseUrl = 'YOUR_BACKEND_URL';
  static const bool useBackendApi = true;
}
```

**Common configurations:**

| Environment | URL | Notes |
|-------------|-----|-------|
| Android Emulator | `http://10.0.2.2:5000` | Special IP for Android emulator to access host machine |
| iOS Simulator | `http://localhost:5000` | Direct localhost access |
| Physical Device | `http://192.168.1.X:5000` | Replace X with your computer's local IP |
| Production | `https://api.yourdomain.com` | Your deployed backend URL |

## Available API Methods

The `FarmModel` class now includes these backend API methods:

### Data Loading
```dart
// Load complete farm state from backend
await model.loadFarmStateFromApi('farmer_id');

// Check if backend is available
bool isHealthy = await model.checkBackendHealth();
```

### Valve Control
```dart
// Open valve for 30 minutes for tomato plant
await model.openValveViaApi('tomato', 30);

// Close valve
await model.closeValveViaApi();
```

### AI Mode
```dart
// Enable AI automatic mode
await model.toggleAiModeViaApi(true);

// Disable AI mode (manual control)
await model.toggleAiModeViaApi(false);

// Request AI irrigation decision
var decision = await model.requestAiDecision();
```

### History
```dart
// Get last 10 irrigation events
var history = await model.getHistoryFromApi(limit: 10);
```

## Usage Example

In your Flutter widget:

```dart
import 'package:provider/provider.dart';
import 'farm_model.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final farmModel = Provider.of<FarmModel>(context);
    
    return ElevatedButton(
      onPressed: () async {
        // Check backend health first
        bool isHealthy = await farmModel.checkBackendHealth();
        if (isHealthy) {
          // Load farm data from backend
          await farmModel.loadFarmStateFromApi('mabrouka_id');
          
          // Open valve if needed
          if (farmModel.soilMoisture == SoilMoisture.dry) {
            await farmModel.openValveViaApi('tomato', 30);
          }
        } else {
          // Fallback to Firebase
          await farmModel.loadFarmerData('mabrouka_id');
        }
      },
      child: Text('Load Farm Data'),
    );
  }
}
```

## Testing the Integration

### 1. Start the Backend

```bash
cd backend
python app.py
```

The backend should start on `http://localhost:5000`

### 2. Test Backend Health

You can test the backend is running by visiting:
- http://localhost:5000/ - API documentation
- http://localhost:5000/health - Health check

### 3. Run the Flutter App

```bash
cd my_app
flutter pub get
flutter run
```

### 4. Test API Calls

Add this to your app initialization to test the connection:

```dart
void initState() {
  super.initState();
  final model = Provider.of<FarmModel>(context, listen: false);
  
  // Test backend connection
  model.checkBackendHealth().then((isHealthy) {
    print('Backend health: $isHealthy');
    if (isHealthy) {
      model.loadFarmStateFromApi('YOUR_FARMER_ID');
    }
  });
}
```

## Backend API Endpoints

The following endpoints are available:

### Farmer Interface (`/api/farmer/<user_id>/`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/state` | Get complete farm state |
| GET | `/plants` | Get user's plants |
| POST | `/valve/open` | Open valve manually |
| POST | `/valve/close` | Close valve manually |
| GET | `/valve/status` | Get valve status |
| POST | `/ai-mode` | Toggle AI automatic mode |
| POST | `/decision` | Get AI irrigation decision |
| GET | `/history` | Get irrigation history |

### Admin Interface (`/api/admin/`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users` | List all users |
| POST | `/users` | Add new user |
| GET | `/users/<id>` | Get user details |
| PUT | `/users/<id>` | Update user |
| DELETE | `/users/<id>` | Delete user |
| POST | `/users/<id>/plants` | Add plant to user |
| GET | `/plants` | List all available plants |
| GET | `/stats` | System statistics |

For detailed API documentation, see `backend/API_DOCUMENTATION.md`

## Troubleshooting

### "Connection refused" error

**Problem:** Cannot connect to backend from mobile device/emulator

**Solutions:**
1. Make sure backend is running: `python backend/app.py`
2. Check firewall allows connections on port 5000
3. For Android Emulator, use `http://10.0.2.2:5000`
4. For physical device, use your computer's IP address (not localhost)

### "Failed to load farm state" error

**Problem:** API returns error or null

**Solutions:**
1. Check backend logs for errors
2. Verify farmer_id exists in Firebase
3. Test endpoint manually: `curl http://localhost:5000/api/farmer/YOUR_ID/state`

### Backend not starting

**Problem:** Backend crashes or won't start

**Solutions:**
1. Check Python dependencies: `pip install -r requirements.txt`
2. Verify Firebase credentials file exists
3. Check backend logs for specific error messages

## Switching Between Firebase and Backend API

You can use both simultaneously or choose one:

### Using Both (Recommended)
```dart
// Load from Firebase for real-time updates
model.listenToMeasurements('farmer_id');

// Use API for actions
await model.openValveViaApi('tomato', 30);
```

### Backend API Only
```dart
// Set in api_config.dart
static const bool useBackendApi = true;

// Use API methods
await model.loadFarmStateFromApi('farmer_id');
```

### Firebase Only (Legacy)
```dart
// Set in api_config.dart
static const bool useBackendApi = false;

// Use Firebase methods
await model.loadFarmerData('farmer_id');
```

## Next Steps

1. **Add Authentication**: Implement user login to get farmer_id automatically
2. **Error Handling**: Add proper error messages in UI when API calls fail
3. **Caching**: Cache API responses to work offline
4. **Real-time Updates**: Consider WebSocket for real-time valve status updates
5. **Testing**: Add unit tests for API service methods

## Support

For issues or questions:
1. Check backend logs: `backend/app.py` output
2. Check Flutter logs: `flutter logs`
3. Review API documentation: `backend/API_DOCUMENTATION.md`
