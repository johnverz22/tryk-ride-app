class MessageThread {
  final int conversationId;
  final String name;
  final String message;
  final DateTime createdAt;

  MessageThread({
    required this.conversationId,
    required this.name,
    required this.message,
    required this.createdAt,
  });

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    return MessageThread(
      conversationId: json['conversation_id'],
      name: json['sender']['name'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get formattedTime {
    final now = DateTime.now();
    if (createdAt.day == now.day &&
        createdAt.month == now.month &&
        createdAt.year == now.year) {
      return '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (createdAt.difference(now).inDays == -1) {
      return 'Yesterday';
    } else {
      return '${createdAt.month}/${createdAt.day}';
    }
  }
}
