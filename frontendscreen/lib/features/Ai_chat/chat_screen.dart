import 'package:flutter/material.dart';
import './chat_message.dart';
import './chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _awaitingApproval = false;
  String _conversationState = 'welcome';

  final String userId = "user_123"; // Replace with real user ID from auth
  Map<String, dynamic> userProfile = {
    "height": 170,
    "weight": 90,
    "goal": "weight loss",
    "days": ["Monday", "Friday"],
    "equipment": false,
    "gender": "male",
    "birthdate": "1990-01-01",
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _sendWelcomeMessage();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await getUserProfile(userId);
      if (profile.isNotEmpty) {
        setState(() {
          userProfile = {
            ...userProfile,
            ...profile,
          };
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  void _sendWelcomeMessage() async {
    setState(() {
      _isLoading = true;
    });

    final response = await sendMessage(
      userId: userId,
      message: "Hello",
      userProfile: userProfile,
    );

    setState(() {
      _isLoading = false;
      messages.add(ChatMessage(
        text: response.reply,
        isUser: false,
        type: response.awaitingApproval 
            ? MessageType.approvalRequest 
            : MessageType.text,
      ));
      _conversationState = response.conversationState;
      _awaitingApproval = response.awaitingApproval;
    });

    _scrollToBottom();
  }

  void sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    // Add loading message
    setState(() {
      messages.add(ChatMessage.loading());
    });
    _scrollToBottom();

    final response = await sendMessage(
      userId: userId,
      message: text,
      userProfile: userProfile,
    );

    setState(() {
      // Remove loading message
      messages.removeWhere((msg) => msg.isLoading);
      
      _isLoading = false;
      
      // Determine message type based on response
      MessageType messageType = MessageType.text;
      if (response.awaitingApproval) {
        messageType = MessageType.approvalRequest;
      } else if (response.planGenerated) {
        messageType = MessageType.plan;
      }

      messages.add(ChatMessage(
        text: response.reply,
        isUser: false,
        type: messageType,
      ));

      _conversationState = response.conversationState;
      _awaitingApproval = response.awaitingApproval;
    });

    _scrollToBottom();
  }

  void _handleApproval(bool approved) async {
    if (approved) {
      // User approved the plan
      setState(() {
        _isLoading = true;
        messages.add(ChatMessage(text: "Yes, approve this plan", isUser: true));
      });
      _scrollToBottom();

      // Call approval endpoint
      final result = await approvePlan(
        userId: userId,
        userProfile: userProfile,
      );

      setState(() {
        _isLoading = false;
        _awaitingApproval = false;
        
        if (result['success']) {
          messages.add(ChatMessage(
            text: "✅ ${result['message']}\n\nYour plan has been saved and you can view it in the 'My Plans' section. Let me know if you have any questions about the exercises!",
            isUser: false,
          ));
        } else {
          messages.add(ChatMessage(
            text: "❌ ${result['message']}\n\nPlease try again or contact support.",
            isUser: false,
          ));
        }
      });
    } else {
      // User rejected the plan
      setState(() {
        messages.add(ChatMessage(text: "No, I'd like to make changes", isUser: true));
      });
      
      sendChatMessage("I'd like to make some changes to the plan");
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Fitness Coach"),
        backgroundColor: Colors.blue[700],
        elevation: 2,
      ),
      body: Column(
        children: [
          // Conversation state indicator
          if (_conversationState != 'chat')
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getStateMessage(),
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

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Approval buttons (shown when awaiting approval)
          if (_awaitingApproval && !_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleApproval(true),
                      icon: const Icon(Icons.check_circle),
                      label: const Text("Yes, Approve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleApproval(false),
                      icon: const Icon(Icons.edit),
                      label: const Text("No, Modify"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _awaitingApproval 
                          ? "Use buttons above to approve/modify"
                          : "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    enabled: !_isLoading && !_awaitingApproval,
                    onSubmitted: (text) {
                      if (text.isNotEmpty && !_awaitingApproval) {
                        sendChatMessage(text);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isLoading || _awaitingApproval
                      ? Colors.grey
                      : Colors.blue[700],
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: (_isLoading || _awaitingApproval)
                        ? null
                        : () {
                            if (_controller.text.isNotEmpty) {
                              sendChatMessage(_controller.text);
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                msg.text,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isUser
              ? Colors.blue[700]
              : (msg.isAwaitingApproval ? Colors.green[50] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
          border: msg.isAwaitingApproval
              ? Border.all(color: Colors.green[300]!, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isPlan || msg.isAwaitingApproval)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      msg.isAwaitingApproval ? Icons.check_circle_outline : Icons.fitness_center,
                      size: 16,
                      color: msg.isAwaitingApproval ? Colors.green[700] : Colors.blue[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      msg.isAwaitingApproval ? "Awaiting Approval" : "Workout Plan",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: msg.isAwaitingApproval ? Colors.green[700] : Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStateMessage() {
    switch (_conversationState) {
      case 'welcome':
        return 'Welcome! Let\'s get started...';
      case 'gathering_info':
        return 'Gathering your preferences...';
      case 'generating_plan':
        return 'Creating your personalized plan...';
      case 'awaiting_approval':
        return 'Review your plan and approve or request changes';
      case 'approved':
        return 'Plan saved! Ready to help with more questions';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
