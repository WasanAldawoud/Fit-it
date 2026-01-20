import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';

// Helper function to get the appropriate HTTP client
http.Client getHttpClient() {
  // For web builds, use BrowserClient to handle cookies
  return BrowserClient();
}

class ChatResponse {
  final String reply;
  final String conversationState;
  final bool planGenerated;
  final bool awaitingApproval;

  ChatResponse({
    required this.reply,
    required this.conversationState,
    required this.planGenerated,
    required this.awaitingApproval,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] ?? '',
      conversationState: json['conversationState'] ?? 'chat',
      planGenerated: json['planGenerated'] ?? false,
      awaitingApproval: json['awaitingApproval'] ?? false,
    );
  }
}

Future<ChatResponse> sendMessage({
  required String message,
  required Map userProfile,
}) async {
  final client = getHttpClient();
  try {
    final response = await client.post(
      Uri.parse("http://localhost:3000/ai/fitness-chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "message": message,
        "userProfile": userProfile,
      }),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        return ChatResponse.fromJson(data);
      } catch (e) {
        return ChatResponse(
          reply: "Error parsing response: $e",
          conversationState: 'chat',
          planGenerated: false,
          awaitingApproval: false,
        );
      }
    } else {
      return ChatResponse(
        reply: "Error: ${response.statusCode} - ${response.body}",
        conversationState: 'chat',
        planGenerated: false,
        awaitingApproval: false,
      );
    }
  } catch (e) {
    return ChatResponse(
      reply: "Network error: $e",
      conversationState: 'chat',
      planGenerated: false,
      awaitingApproval: false,
    );
  }
}

Future<Map<String, dynamic>> approvePlan({
  required String userId,
  required Map userProfile,
}) async {
  final client = getHttpClient();
  try {
    final response = await client.post(
      Uri.parse("http://localhost:3000/ai/approve-plan"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "userProfile": userProfile,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'message': data['message'] ?? 'Plan approved successfully!',
        'planId': data['planId'],
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to approve plan: ${response.statusCode}',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Network error: $e',
    };
  }
}

Future<Map<String, dynamic>> getUserProfile(String userId) async {
  final client = getHttpClient();
  try {
    final response = await client.get(
      Uri.parse("http://localhost:3000/auth/profile"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user'] ?? {};
    } else {
      return {};
    }
  } catch (e) {
    print('Error fetching user profile: $e');
    return {};
  }
}
