import 'package:http/http.dart' as http;
import 'dart:convert';

class GeminiService {
  static const String _apiKey = 'AIzaSyDJpW9h_UIh7xYPOnki-2GAY0mLn6xGcWQ';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent';
  static const String _backendUrl = 'http://localhost:8000/prompt';

  Future<String> generateResponse(String query, String promptStyle) async {
    try {
      print('Calling Gemini API with query: $query');

      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text":
                    promptStyle == "Casual and Creative"
                        ? "Respond in a casual and creative way to this query: $query"
                        : "Provide a formal and analytical response to this query: $query",
              },
            ],
          },
        ],
      };

      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('API Response status: ${response.statusCode}');
      print('API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          throw Exception('No valid response data found');
        }
      } else {
        throw Exception('API call failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in generateResponse: $e');
      rethrow;
    }
  }

  Future<bool> saveToBackend({
    required String userId,
    required String query,
    required String casualResponse,
    required String formalResponse,
  }) async {
    try {
      print('Saving to backend with data: $userId, $query');

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'query': query,
          'casual_response': casualResponse,
          'formal_response': formalResponse,
        }),
      );

      print('Backend Response status: ${response.statusCode}');
      print('Backend Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error in saveToBackend: $e');
      return false;
    }
  }
}
