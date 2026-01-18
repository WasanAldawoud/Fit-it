import 'dart:convert';
import 'package:http/http.dart' as http;

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
  required String userId,
  required String message,
  required Map userProfile,
}) async {
  try {
    final response = await http.post(
      Uri.parse("http://localhost:3000/ai/fitness-chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
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
  try {
    final response = await http.post(
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
  try {
    final response = await http.get(
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
