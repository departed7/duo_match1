class ChatMessage {
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  bool isRead;

  ChatMessage({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isMe': isMe,
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String currentUserId) {
    return ChatMessage(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isMe: (map['senderId'] ?? '') == currentUserId,
      isRead: map['isRead'] ?? false,
    );
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}