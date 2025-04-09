import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to interact with the custom token generation Cloud Function
class TokenService {
  static const String _tokenEndpoint =
      'https://us-central1-smokelog-17303.cloudfunctions.net/generate_refresh_token';

  /// Generate a custom Firebase token valid for 48 hours for the given user ID
  Future<Map<String, dynamic>> generateCustomToken(String uid) async {
    try {
      debugPrint('Requesting custom token for user: $uid');

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('Custom token received successfully');
        return {
          'customToken': data['customToken'],
          'expiresIn':
              data['expiresIn'] ?? 172800, // Default 48 hours in seconds
        };
      } else {
        throw Exception(
            'Failed to generate custom token: HTTP ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('Error generating custom token: $e');
      rethrow;
    }
  }
}
