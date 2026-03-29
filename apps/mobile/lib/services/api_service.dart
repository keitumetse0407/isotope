// ISOTOPE — API Service
// Connects Flutter app to FastAPI/n8n backend
// VPS: 185.167.97.193

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/signal.dart';
import '../models/user.dart';
import '../models/portfolio.dart';
import '../screens/admin_dashboard.dart';

class ApiService {
  // Backend URL - Update when deploying
  static const String baseUrl = 'http://185.167.97.193:8100';
  
  final http.Client _client = http.Client();

  // ============================================
  // USER ENDPOINTS
  // ============================================

  Future<User?> getUser(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return User.fromJson(json);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<User?> createUser(String email, String name) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
        }),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return User.fromJson(json);
      }
      return null;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  Future<bool> acceptDisclaimer(String userId) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/users/$userId/disclaimer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accepted': true,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error accepting disclaimer: $e');
      return false;
    }
  }

  Future<bool> startTrial(String userId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/users/$userId/trial'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error starting trial: $e');
      return false;
    }
  }

  // ============================================
  // SIGNAL ENDPOINTS
  // ============================================

  Future<List<Signal>> getSignals({String? tier}) async {
    try {
      String url = '$baseUrl/signals';
      if (tier != null) {
        url += '?tier=$tier';
      }

      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List jsonList = jsonDecode(response.body);
        return jsonList.map((j) => Signal.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching signals: $e');
      return [];
    }
  }

  Future<Signal?> getSignalById(String signalId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/signals/$signalId'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Signal.fromJson(json);
      }
      return null;
    } catch (e) {
      print('Error fetching signal: $e');
      return null;
    }
  }

  // ============================================
  // PORTFOLIO ENDPOINTS
  // ============================================

  Future<Portfolio?> getPortfolio(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId/portfolio'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Portfolio.fromJson(json);
      }
      return null;
    } catch (e) {
      print('Error fetching portfolio: $e');
      return null;
    }
  }

  // ============================================
  // PAYMENT ENDPOINTS (Yoco)
  // ============================================

  Future<String?> createPaymentLink(String userId, String plan) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/payments/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'plan': plan, // 'trial', 'pro', 'elite'
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['paymentUrl'] as String?;
      }
      return null;
    } catch (e) {
      print('Error creating payment link: $e');
      return null;
    }
  }

  Future<bool> verifyPayment(String paymentId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/payments/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'paymentId': paymentId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error verifying payment: $e');
      return false;
    }
  }

  // ============================================
  // PUBLIC PERFORMANCE (Google Sheet via n8n)
  // ============================================

  Future<Map<String, dynamic>?> getPublicPerformance() async {
    try {
      // This hits n8n webhook which fetches from Google Sheets
      final response = await _client.get(
        Uri.parse('$baseUrl/public/performance'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching performance: $e');
      return null;
    }
  }

  // ============================================
  // ADMIN ENDPOINTS
  // ============================================

  Future<AdminStats?> getAdminStats() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/admin/stats'),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return AdminStats.fromJson(json);
      }
      // Fallback to mock data
      return AdminStats(
        totalUsers: 0,
        trialUsers: 0,
        proUsers: 0,
        eliteUsers: 0,
        mrr: 0.0,
        todayRevenue: 0.0,
        totalRevenue: 0.0,
        totalSignals: 1,
        wins: 1,
        losses: 0,
        automationStatus: {},
      );
    } catch (e) {
      print('Error fetching admin stats: $e');
      return AdminStats(
        totalUsers: 0,
        trialUsers: 0,
        proUsers: 0,
        eliteUsers: 0,
        mrr: 0.0,
        todayRevenue: 0.0,
        totalRevenue: 0.0,
        totalSignals: 1,
        wins: 1,
        losses: 0,
        automationStatus: {},
      );
    }
  }

  // ============================================
  // PREDICTION MARKET ENDPOINTS
  // ============================================

  Future<List<Map<String, dynamic>>?> getPredictions() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/predictions'),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching predictions: $e');
      return null;
    }
  }

  Future<bool> voteOnPrediction(String predictionId, String vote) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/predictions/vote?prediction_id=$predictionId&vote=$vote'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error voting on prediction: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getLeaderboard() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/leaderboard'),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return null;
    }
  }

  // ============================================
  // HEALTH CHECK
  // ============================================

  Future<bool> isBackendHealthy() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('Backend health check failed: $e');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
