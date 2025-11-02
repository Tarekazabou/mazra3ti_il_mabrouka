# 🌱 Mazra3ti Il Mabrouka - WiEmpower Smart Irrigation System

An AI-powered smart irrigation system for women farmers in Tunisia. The system provides automated irrigation decisions, manual control, and real-time monitoring through a mobile app.

## 📋 Project Structure

```
mazra3ti_il_mabrouka/
├── backend/              # Flask API backend
│   ├── app.py           # Main Flask application
│   ├── routes/          # API route handlers
│   ├── services/        # Business logic
│   ├── utils/           # Utility functions
│   └── requirements.txt # Python dependencies
│
├── my_app/              # Flutter mobile application
│   ├── lib/            # Flutter source code
│   │   ├── api_service.dart      # Backend API client
│   │   ├── api_config.dart       # API configuration
│   │   ├── firebase_service.dart # Firebase client
│   │   ├── farm_model.dart       # App state management
│   │   └── main.dart             # App entry point
│   ├── pubspec.yaml    # Flutter dependencies
│   └── INTEGRATION_README.md # Frontend-backend integration guide
│
└── SETUP_GUIDE.md      # Quick setup instructions
```

## ✨ Features

### For Farmers
- 📱 **Mobile App Interface** - Easy-to-use mobile app in Arabic
- 🌡️ **Real-time Monitoring** - Track soil moisture, temperature, and humidity
- 💧 **Manual Valve Control** - Open/close irrigation valves from the app
- 🤖 **AI Automatic Mode** - Let AI decide when to water based on data
- 📊 **Irrigation History** - View past irrigation events
- 🌤️ **Weather Integration** - Get weather forecasts and alerts
- 🗣️ **Voice Assistant** - Arabic voice interaction for easier use

### For Administrators
- 👥 **User Management** - Add, update, and manage farmers
- 🌿 **Plant Database** - Manage crop information and requirements
- 📈 **System Statistics** - Monitor system-wide metrics
- 🔧 **Configuration** - System settings and parameters

### Technology Stack
- **Backend**: Flask (Python) + Firebase
- **Frontend**: Flutter (Dart)
- **AI/ML**: XGBoost + Google Gemini API
- **Database**: Firebase Firestore
- **Real-time**: Firebase real-time database

## 🚀 Quick Start

### Prerequisites
- Python 3.8 or higher
- Flutter SDK 3.9.2 or higher
- Firebase project with credentials
- Git

### 1. Clone the Repository
```bash
git clone https://github.com/Tarekazabou/mazra3ti_il_mabrouka.git
cd mazra3ti_il_mabrouka
```

### 2. Setup Backend
```bash
cd backend
pip install -r requirements.txt
python app.py
```

Backend will start on `http://localhost:5000`

### 3. Setup Frontend
```bash
cd my_app
flutter pub get
flutter run
```

For detailed setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md)

## 🔗 Frontend-Backend Integration

The Flutter app (my_app) is now fully integrated with the Flask backend:

```
┌─────────────────────────┐
│   Flutter Mobile App    │
│      (my_app)          │
└───────────┬─────────────┘
            │
            ├─── HTTP REST API ───┐
            │                     │
            │               ┌─────▼──────┐
            │               │   Flask    │
            │               │  Backend   │
            │               │  (port     │
            │               │   5000)    │
            │               └─────┬──────┘
            │                     │
            └─── Firebase ────────┴──────┐
                                          │
                                    ┌─────▼──────┐
                                    │  Firebase  │
                                    │ Firestore  │
                                    └────────────┘
```

### Key Integration Points

1. **API Service** (`my_app/lib/api_service.dart`)
   - Handles all HTTP requests to backend
   - Endpoints for valve control, farm state, AI decisions

2. **Farm Model** (`my_app/lib/farm_model.dart`)
   - Integrates both Firebase and Backend API
   - Provides unified interface for data access

3. **Configuration** (`my_app/lib/api_config.dart`)
   - Easy configuration of backend URL
   - Support for different environments (dev/prod)

For detailed integration documentation, see [my_app/INTEGRATION_README.md](my_app/INTEGRATION_README.md)

## 📚 Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Quick setup instructions
- **[my_app/INTEGRATION_README.md](my_app/INTEGRATION_README.md)** - Frontend-backend integration details
- **[backend/API_DOCUMENTATION.md](backend/API_DOCUMENTATION.md)** - Complete API reference
- **[backend/BACKEND_STRUCTURE.md](backend/BACKEND_STRUCTURE.md)** - Backend architecture
- **[backend/BACKEND_README.md](backend/BACKEND_README.md)** - Backend setup details

## 🌐 API Endpoints

### Farmer Interface
Base URL: `/api/farmer/<user_id>`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/state` | Get complete farm state |
| POST | `/valve/open` | Open irrigation valve |
| POST | `/valve/close` | Close irrigation valve |
| GET | `/valve/status` | Get valve status |
| POST | `/ai-mode` | Toggle AI automatic mode |
| POST | `/decision` | Get AI irrigation decision |
| GET | `/history` | Get irrigation history |
| GET | `/plants` | Get user's plants |

### Admin Interface
Base URL: `/api/admin`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users` | List all users |
| POST | `/users` | Create new user |
| GET | `/users/<id>` | Get user details |
| PUT | `/users/<id>` | Update user |
| DELETE | `/users/<id>` | Delete user |
| GET | `/plants` | List all plants |
| GET | `/stats` | System statistics |

## 🧪 Testing

### Test Backend Health
```bash
curl http://localhost:5000/health
```

### Test Farm State API
```bash
curl http://localhost:5000/api/farmer/YOUR_FARMER_ID/state
```

### Test from Flutter App
```dart
final farmModel = Provider.of<FarmModel>(context, listen: false);
bool isHealthy = await farmModel.checkBackendHealth();
await farmModel.loadFarmStateFromApi('farmer_id');
```

## 🐛 Troubleshooting

### Backend Issues
- **Port already in use**: Change port in `backend/app.py` (line 110)
- **Firebase credentials error**: Verify `.json` file exists in `backend/`
- **Module not found**: Run `pip install -r requirements.txt`

### Frontend Issues
- **Cannot connect to backend**: 
  - Check backend is running
  - Update `baseUrl` in `my_app/lib/api_config.dart`
  - For Android emulator: use `http://10.0.2.2:5000`
  - For iOS simulator: use `http://localhost:5000`
  - For physical device: use your computer's IP
- **Package not found**: Run `flutter pub get`

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for more troubleshooting tips.

## 🔒 Security Notes

- Never commit Firebase credentials to Git
- Use environment variables for sensitive data in production
- Enable authentication before deploying to production
- Use HTTPS in production (backend already has CORS enabled)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is part of the WiEmpower initiative supporting women farmers in Tunisia.

## 👥 Contact

For questions or support, please open an issue in the GitHub repository.

## 🎯 Roadmap

- [ ] Add user authentication (login/register)
- [ ] Real-time WebSocket updates for valve status
- [ ] Offline mode with local caching
- [ ] Multi-language support (Arabic, French, English)
- [ ] Push notifications for alerts
- [ ] Integration with weather APIs
- [ ] Historical data analytics dashboard
- [ ] Mobile app for iOS

## 🙏 Acknowledgments

This project aims to empower women farmers in Tunisia through smart irrigation technology, helping them make better decisions about water usage and crop management.
