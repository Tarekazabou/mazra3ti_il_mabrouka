import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  // Backend API base URL from configuration
  String get baseUrl => ApiConfig.baseUrl;
  
  /// Get complete farm state from backend API
  Future<Map<String, dynamic>?> getFarmState(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/farmer/$userId/state'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load farm state: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching farm state: $e');
      return null;
    }
  }

  /// Get user's plants from backend API
  Future<List<Map<String, dynamic>>> getUserPlants(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/farmer/$userId/plants'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['plants'] is List) {
          return List<Map<String, dynamic>>.from(data['plants']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching plants: $e');
      return [];
    }
  }

  /// Open valve manually
  Future<Map<String, dynamic>?> openValve(
    String userId, 
    String plantName, 
    int durationMinutes,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/farmer/$userId/valve/open'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'plant_name': plantName,
          'duration_minutes': durationMinutes,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to open valve: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error opening valve: $e');
      return null;
    }
  }

  /// Close valve manually
  Future<Map<String, dynamic>?> closeValve(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/farmer/$userId/valve/close'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to close valve: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error closing valve: $e');
      return null;
    }
  }

  /// Get valve status
  Future<Map<String, dynamic>?> getValveStatus(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/farmer/$userId/valve/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to get valve status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting valve status: $e');
      return null;
    }
  }

  /// Toggle AI mode
  Future<Map<String, dynamic>?> toggleAiMode(String userId, bool enabled) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/farmer/$userId/ai-mode'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'enabled': enabled,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to toggle AI mode: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error toggling AI mode: $e');
      return null;
    }
  }

  /// Get irrigation history
  Future<List<Map<String, dynamic>>> getHistory(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/farmer/$userId/history?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['history'] is List) {
          return List<Map<String, dynamic>>.from(data['history']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  /// Request AI irrigation decision
  Future<Map<String, dynamic>?> getAiDecision(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/farmer/$userId/decision'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to get AI decision: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting AI decision: $e');
      return null;
    }
  }

  /// Health check endpoint
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error checking health: $e');
      return false;
    }
  }
}
