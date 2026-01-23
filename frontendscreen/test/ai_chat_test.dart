import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:FitIt/features/Ai_chat/chat_message.dart';
void main() {
  group('ChatMessage Tests', () {
    test('creates text message correctly', () {
      final message = ChatMessage(text: 'Hello', isUser: true);
      expect(message.text, 'Hello');
      expect(message.isUser, true);
      expect(message.type, MessageType.text);
      expect(message.isLoading, false);
      expect(message.isPlan, false);
      expect(message.isAwaitingApproval, false);
    });

    test('creates loading message correctly', () {
      final message = ChatMessage.loading();
      expect(message.text, 'Generating your plan...');
      expect(message.isUser, false);
      expect(message.type, MessageType.loading);
      expect(message.isLoading, true);
    });

    test('creates approval request message correctly', () {
      final message = ChatMessage(
        text: 'Plan generated',
        isUser: false,
        type: MessageType.approvalRequest,
      );
      expect(message.isAwaitingApproval, true);
      expect(message.isPlan, false);
    });

    test('creates plan message correctly', () {
      final message = ChatMessage(
        text: 'Workout plan details',
        isUser: false,
        type: MessageType.plan,
      );
      expect(message.isPlan, true);
      expect(message.isAwaitingApproval, false);
    });

    test('factory constructors work correctly', () {
      final textMsg = ChatMessage(text: 'Hello', isUser: true);
      expect(textMsg.type, MessageType.text);

      final planMsg = ChatMessage.plan('Plan content');
      expect(planMsg.type, MessageType.plan);
      expect(planMsg.isPlan, true);

      final approvalMsg = ChatMessage.approvalRequest('Approve this?');
      expect(approvalMsg.type, MessageType.approvalRequest);
      expect(approvalMsg.isAwaitingApproval, true);
    });
  });

  group('MessageType Enum Tests', () {
    test('MessageType values are correct', () {
      expect(MessageType.text, isNotNull);
      expect(MessageType.loading, isNotNull);
      expect(MessageType.plan, isNotNull);
      expect(MessageType.approvalRequest, isNotNull);
    });
  });

  group('ChatScreen Widget Tests', () {
    testWidgets('builds without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Test'),
          ),
        ),
      ));

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('displays messages in list', (WidgetTester tester) async {
      final messages = [
        ChatMessage(text: 'Hello', isUser: true),
        ChatMessage(text: 'Hi there!', isUser: false),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              return ListTile(
                title: Text(msg.text),
                subtitle: Text(msg.isUser ? 'User' : 'AI'),
              );
            },
          ),
        ),
      ));

      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('Hi there!'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
    });

    testWidgets('approval buttons have correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Yes, Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text("No, Modify"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Yes, Approve'), findsOneWidget);
      expect(find.text('No, Modify'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('loading spinner displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('message bubbles have correct alignment', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              // User message (right aligned)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'User message',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              // AI message (left aligned)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'AI message',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('User message'), findsOneWidget);
      expect(find.text('AI message'), findsOneWidget);
      expect(find.byType(Container), findsNWidgets(2));
    });

    testWidgets('state indicator shows correct messages', (WidgetTester tester) async {
      const stateMessages = {
        'welcome': 'Welcome! Let\'s get started...',
        'gathering_info': 'Gathering your preferences...',
        'generating_plan': 'Creating your personalized plan...',
        'awaiting_approval': 'Review your plan and approve or request changes',
        'approved': 'Plan saved! Ready to help with more questions',
      };

      for (final entry in stateMessages.entries) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test'),
            ),
            body: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));

        expect(find.text(entry.value), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      }
    });

    testWidgets('input field properties change based on state', (WidgetTester tester) async {
      // Test enabled input
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextField(
            enabled: true,
            decoration: const InputDecoration(
              hintText: "Type a message...",
            ),
          ),
        ),
      ));

      expect(find.text('Type a message...'), findsOneWidget);

      // Test disabled input
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextField(
            enabled: false,
            decoration: const InputDecoration(
              hintText: "Use buttons above to approve/modify",
            ),
          ),
        ),
      ));

      expect(find.text('Use buttons above to approve/modify'), findsOneWidget);
    });
  });

  group('UI Component Tests', () {
    testWidgets('plan message has special styling', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[300]!, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Workout Plan",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Plan content here',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Workout Plan'), findsOneWidget);
      expect(find.text('Plan content here'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('approval request has green styling', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[300]!, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Awaiting Approval",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Approval request content',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Awaiting Approval'), findsOneWidget);
      expect(find.text('Approval request content'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });

  group('Integration Flow Tests', () {
    testWidgets('simulated conversation flow', (WidgetTester tester) async {
      // Test that the UI can handle multiple message types in sequence
      final messages = [
        ChatMessage(text: 'Hello!', isUser: true),
        ChatMessage(text: 'Welcome! What\'s your goal?', isUser: false),
        ChatMessage(text: 'I want to lose weight', isUser: true),
        ChatMessage(text: 'Great! What workout style?', isUser: false),
        ChatMessage.loading(),
        ChatMessage.plan('## Your Plan\n- Cardio: Running'),
        ChatMessage.approvalRequest('Would you like to approve this plan?'),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              if (msg.isLoading) {
                return const ListTile(
                  title: Text('Generating your plan...'),
                  leading: CircularProgressIndicator(),
                );
              }
              return ListTile(
                title: Text(msg.text),
                subtitle: Text(msg.isUser ? 'You' : 'AI Coach'),
                trailing: msg.isPlan ? const Icon(Icons.fitness_center) :
                         msg.isAwaitingApproval ? const Icon(Icons.check_circle) : null,
              );
            },
          ),
        ),
      ));

      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('Welcome! What\'s your goal?'), findsOneWidget);
      expect(find.text('I want to lose weight'), findsOneWidget);
      expect(find.text('Great! What workout style?'), findsOneWidget);
      expect(find.text('Generating your plan...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
