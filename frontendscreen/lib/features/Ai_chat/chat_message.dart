enum MessageType {
  text,
  loading,
  plan,
  approvalRequest,
}

class ChatMessage {
  final String text;
  final bool isUser;
  final MessageType type;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
    this.metadata,
  });

  // Factory constructor for loading message
  factory ChatMessage.loading() {
    return ChatMessage(
      text: "Generating your plan...",
      isUser: false,
      type: MessageType.loading,
    );
  }

  // Factory constructor for plan message
  factory ChatMessage.plan(String planText, {Map<String, dynamic>? planData}) {
    return ChatMessage(
      text: planText,
      isUser: false,
      type: MessageType.plan,
      metadata: planData,
    );
  }

  // Factory constructor for approval request
  factory ChatMessage.approvalRequest(String text) {
    return ChatMessage(
      text: text,
      isUser: false,
      type: MessageType.approvalRequest,
    );
  }

  // Check if message is awaiting approval
  bool get isAwaitingApproval => type == MessageType.approvalRequest;

  // Check if message is a plan
  bool get isPlan => type == MessageType.plan;

  // Check if message is loading
  bool get isLoading => type == MessageType.loading;
}
