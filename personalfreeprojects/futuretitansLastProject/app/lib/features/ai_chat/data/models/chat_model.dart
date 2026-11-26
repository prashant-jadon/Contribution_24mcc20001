class ChatMessageModel {
  final String role; // 'user' or 'assistant'
  final String message;
  final DateTime timestamp;

  ChatMessageModel({
    required this.role,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      role: json['role'] ?? 'user',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ChatHistoryModel {
  final List<ChatMessageModel> conversation;
  final Map<String, dynamic>? ssiScore;
  final bool isCompleted;
  final int timeSpent;

  ChatHistoryModel({
    required this.conversation,
    this.ssiScore,
    this.isCompleted = false,
    this.timeSpent = 0,
  });

  factory ChatHistoryModel.fromJson(Map<String, dynamic> json) {
    return ChatHistoryModel(
      conversation: (json['conversation'] as List?)
              ?.map((m) => ChatMessageModel.fromJson(m))
              .toList() ??
          [],
      ssiScore: json['ssiScore'],
      isCompleted: json['isCompleted'] ?? false,
      timeSpent: json['timeSpent'] ?? 0,
    );
  }
}
