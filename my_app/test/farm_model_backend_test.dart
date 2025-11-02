import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/farm_model.dart' as fm;

// NOTE:
// This test spins up a tiny fake HTTP server on http://localhost:5000
// to simulate the Flask backend API so we can verify FarmModel wiring.
// Make sure the real backend is NOT running on the same port when running tests.
// (ApiConfig.baseUrl is fixed to http://localhost:5000.)
void main() {
  HttpServer? server;

  setUpAll(() async {
    // Start a local fake backend on port 5000
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 5000);
    server!.listen((HttpRequest request) async {
      final path = request.uri.path;
      final method = request.method.toUpperCase();
      request.response.headers.contentType = ContentType.json;

      // GET /api/farmer/<id>/state
      final stateMatch = RegExp(r'^/api/farmer/([^/]+)/state$').firstMatch(path);
      // POST /api/farmer/<id>/decision
      final decisionMatch = RegExp(r'^/api/farmer/([^/]+)/decision$').firstMatch(path);

      if (method == 'GET' && stateMatch != null) {
        final userId = stateMatch.group(1);
        final response = {
          'success': true,
          'user': {
            'id': userId,
            'name': 'Mabrouka',
            'ai_mode': true,
          },
          'plants': [
            {
              'name': 'citrus',
              'features': {
                'water_requirement_level': 2,
                'root_depth_cm': 35,
                'drought_tolerance': 1,
                'critical_moisture_threshold': 40,
              }
            }
          ],
          'valve': {
            'is_watering': false,
            'mode': 'auto',
          },
          'ai_mode': true,
          'weather': {
            'temperature': 30,
            'will_rain_soon': false,
            'summary': 'Sunny',
          },
        };
        request.response.write(jsonEncode(response));
        await request.response.close();
        return;
      }

      if (method == 'POST' && decisionMatch != null) {
        // Read body (optional)
        final raw = await utf8.decoder.bind(request).join();
        // We parse the body for completeness, but don't validate content in this fake server
        try { jsonDecode(raw) as Map<String, dynamic>; } catch (_) {}

        final response = {
          'success': true,
          'watering_in_progress': false,
          'decision': {
            'should_water': true,
            'duration_minutes': 20,
            'intensity_percent': 60,
            'confidence': 0.85,
          },
          'reasoning': 'التربة جافة نسبيًا والطقس مشمس، يُوصى بالري.',
          'weather': {
            'current': {
              'temperature': 30,
              'humidity': 50,
            },
          },
        };
        request.response.write(jsonEncode(response));
        await request.response.close();
        return;
      }

      // Default 404 for unknown routes
      request.response.statusCode = 404;
      request.response.write(jsonEncode({'success': false, 'error': 'not found'}));
      await request.response.close();
    });
  });

  tearDownAll(() async {
    await server?.close(force: true);
  });

  test('loadFarmStateFromApi populates model from backend', () async {
    final model = fm.FarmModel();

    await model.loadFarmStateFromApi('test_user');

    expect(model.farmerName, equals('Mabrouka'));
    expect(model.vegetation, isNotEmpty);
    expect(model.vegetation.first, equals('citrus'));
    // Valve is closed per fake state
    expect(model.valveStatus, equals(fm.ValveStatus.closed));
    // AI mode ON should map to automatic
    expect(model.controlMode, equals(fm.ControlMode.automatic));
  });

  test('requestAiDecision updates main status based on AI', () async {
    final model = fm.FarmModel();
    // Populate vegetation so requestAiDecision has a plant
    await model.loadFarmStateFromApi('test_user');

    final result = await model.requestAiDecision();
    expect(result, isNotNull);
    expect(result!['success'], isTrue);

    // With should_water=true, main status should reflect AI
    expect(model.getMainStatusText(), equals('اسقِ الآن'));
    final sub = model.getMainStatusSubText();
    expect(sub, contains('مدة الري الموصى بها'));
    expect(sub, contains('20'));
    // Color should be green on positive watering decision
    expect(model.getMainStatusColor(), equals(Colors.green));
  });
}
