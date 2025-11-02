/// API Configuration
/// 
/// This file contains the configuration for connecting the Flutter app
/// to the backend API.
class ApiConfig {
  /// Backend API base URL
  /// 
  /// For local development (backend running on same machine):
  /// - Android Emulator: 'http://10.0.2.2:5000'
  /// - iOS Simulator: 'http://localhost:5000' or 'http://127.0.0.1:5000'
  /// - Physical Device: 'http://YOUR_COMPUTER_IP:5000' (e.g., 'http://192.168.1.100:5000')
  /// - Web Browser: 'http://localhost:5000' or 'http://127.0.0.1:5000'
  /// 
  /// For production deployment:
  /// - Update with your deployed backend URL (e.g., 'https://api.yourdomain.com')
  static const String baseUrl = 'http://localhost:5000';
  
  /// Connection timeout in seconds
  static const int timeoutSeconds = 30;
  
  /// Whether to use the backend API or only Firebase
  /// Set to false to use Firebase only (legacy mode)
  static const bool useBackendApi = true;
}
