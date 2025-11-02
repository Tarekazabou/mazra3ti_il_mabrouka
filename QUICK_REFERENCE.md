# 🚀 Quick Reference - Frontend-Backend Integration

## Essential Files

### Configuration (MUST UPDATE)
```
my_app/lib/api_config.dart  ← Update backend URL here!
```

### Core Integration Files
```
my_app/lib/api_service.dart     - HTTP client for backend
my_app/lib/farm_model.dart      - State management with API methods
backend/app.py                   - Backend server
backend/requirements.txt         - Python dependencies
```

## Quick Commands

### Backend
```bash
# Install dependencies
cd backend && pip install -r requirements.txt

# Start server
python app.py

# Test health
curl http://localhost:5000/health
```

### Frontend
```bash
# Install dependencies
cd my_app && flutter pub get

# Run app
flutter run

# Build
flutter build apk  # Android
flutter build ios  # iOS
```

## Configuration Cheat Sheet

### For Android Emulator
```dart
// In api_config.dart
static const String baseUrl = 'http://10.0.2.2:5000';
```

### For iOS Simulator
```dart
static const String baseUrl = 'http://localhost:5000';
```

### For Physical Device
```dart
// Replace with your computer's IP
static const String baseUrl = 'http://192.168.1.100:5000';
```

### For Production
```dart
static const String baseUrl = 'https://your-backend-domain.com';
```

## API Methods Quick Reference

### Load Data
```dart
final model = Provider.of<FarmModel>(context, listen: false);

// From backend API
await model.loadFarmStateFromApi('farmer_id');

// From Firebase (original)
await model.loadFarmerData('farmer_id');

// Health check
bool ok = await model.checkBackendHealth();
```

### Control Valve
```dart
// Open valve
await model.openValveViaApi('tomato', 30);  // 30 min

// Close valve
await model.closeValveViaApi();

// Check status
final status = await model.getValveStatus('farmer_id');
```

### AI Mode
```dart
// Enable AI
await model.toggleAiModeViaApi(true);

// Disable AI (manual mode)
await model.toggleAiModeViaApi(false);

// Get AI decision
final decision = await model.requestAiDecision();
```

### History
```dart
// Get last 10 events
final history = await model.getHistoryFromApi(limit: 10);
```

## Backend API Endpoints

### Farmer Endpoints
```
GET    /api/farmer/<user_id>/state          - Get farm state
POST   /api/farmer/<user_id>/valve/open     - Open valve
POST   /api/farmer/<user_id>/valve/close    - Close valve
GET    /api/farmer/<user_id>/valve/status   - Valve status
POST   /api/farmer/<user_id>/ai-mode        - Toggle AI
POST   /api/farmer/<user_id>/decision       - AI decision
GET    /api/farmer/<user_id>/history        - History
GET    /api/farmer/<user_id>/plants         - Get plants
```

### Admin Endpoints
```
GET    /api/admin/users                     - List users
POST   /api/admin/users                     - Create user
GET    /api/admin/users/<id>                - Get user
PUT    /api/admin/users/<id>                - Update user
DELETE /api/admin/users/<id>                - Delete user
GET    /api/admin/plants                    - List plants
GET    /api/admin/stats                     - Statistics
```

### System Endpoints
```
GET    /                                    - API docs
GET    /health                              - Health check
```

## Testing Checklist

### Backend
- [ ] `python app.py` starts without errors
- [ ] `curl http://localhost:5000/health` returns healthy
- [ ] Firebase credentials file exists
- [ ] Port 5000 is not in use by another service

### Frontend
- [ ] `flutter pub get` succeeds
- [ ] `api_config.dart` has correct backend URL
- [ ] App builds without errors
- [ ] App can connect to backend (check logs)

### Integration
- [ ] Can load farm state from backend
- [ ] Can open/close valve via API
- [ ] Can toggle AI mode
- [ ] Firebase still works independently
- [ ] Error handling works (try with backend off)

## Common Errors & Fixes

### "Connection refused"
- ✓ Check backend is running
- ✓ Check firewall/port 5000
- ✓ Use correct IP for device type

### "Module not found" (Python)
- ✓ Run: `pip install -r backend/requirements.txt`

### "Package not found" (Flutter)
- ✓ Run: `flutter pub get`
- ✓ Try: `flutter clean && flutter pub get`

### "Firebase error"
- ✓ Check credentials file exists in backend/
- ✓ Verify Firebase project is set up

### "CORS error"
- ✓ Backend has `flask-cors` installed
- ✓ `CORS(app)` is in app.py (already there)

## Architecture Overview

```
Flutter App (my_app)
      │
      ├─── Firebase ────────────┐
      │    (real-time data)      │
      │                          ▼
      └─── HTTP API ──────▶ Flask Backend ──▶ Firebase
           (actions/AI)      (port 5000)       (database)
```

## Documentation Map

### Getting Started
1. **README.md** - Start here, project overview
2. **SETUP_GUIDE.md** - Step-by-step setup
3. **QUICK_REFERENCE.md** - This file!

### Integration Details
4. **my_app/INTEGRATION_README.md** - Integration guide
5. **INTEGRATION_EXAMPLES.md** - Code examples
6. **INTEGRATION_SUMMARY.md** - Complete summary

### API Reference
7. **backend/API_DOCUMENTATION.md** - Full API docs

## Minimal Working Example

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'farm_model.dart';

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('API Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final model = Provider.of<FarmModel>(
              context, 
              listen: false,
            );
            
            // Test connection
            bool healthy = await model.checkBackendHealth();
            print('Backend: ${healthy ? "✅" : "❌"}');
            
            if (healthy) {
              // Load data
              await model.loadFarmStateFromApi('test_id');
              print('Loaded: ${model.farmerName}');
            }
          },
          child: Text('Test API'),
        ),
      ),
    );
  }
}
```

## Get Help

### Check Logs
```bash
# Backend logs
# (visible in terminal where python app.py runs)

# Flutter logs
flutter logs

# Network traffic (if needed)
# Use Flutter DevTools
```

### Debug Steps
1. Verify backend is running: `curl localhost:5000/health`
2. Check Flutter can connect: Run app and check logs
3. Test endpoints manually: Use curl or Postman
4. Review configuration: Check `api_config.dart`
5. Check documentation: Refer to guides above

## Next Steps After Integration

1. **Add Authentication**
   - Implement login screen
   - Get real farmer IDs
   - Store credentials securely

2. **Update UI**
   - Use API methods in widgets
   - Add loading indicators
   - Show error messages

3. **Testing**
   - Test all features end-to-end
   - Test offline behavior
   - Test on multiple devices

4. **Deployment**
   - Deploy backend to cloud
   - Update production URL
   - Set up CI/CD

## Support

- **Questions?** Check documentation files
- **Errors?** See troubleshooting in SETUP_GUIDE.md
- **Examples?** See INTEGRATION_EXAMPLES.md
- **API Reference?** See backend/API_DOCUMENTATION.md

---

**Status**: ✅ Integration Complete - Ready for Testing

**Last Updated**: 2025-11-02
