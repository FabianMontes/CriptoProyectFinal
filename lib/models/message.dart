import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;
  final bool isRead;

  Message({
    required this.senderEmail,
    required this.senderID,
    required this.receiverID,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  // convert to a map
  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}
