class ChatKey {
  final String chatId;
  final String key;
  
  ChatKey({
    required this.chatId,
    required this.key,
  });

  // convert to a map
  Map<String, dynamic> toMap() {
    return {
      'chat_ID': chatId,
      'key': key,
    };
  }
}