import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/chatKey.dart';
import '../../models/message.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';import 'package:crypto/crypto.dart'; 




class ChatService extends ChangeNotifier {
  


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['email'] != _auth.currentUser!.email)
          .map((doc) => doc.data())
          .toList();
    });
  }



  // Consigue todos los usuarios excepto los bloqueados
  Stream<List<Map<String, dynamic>>> getUsersStreamExcludingBlocked() {
    final currentUser = _auth.currentUser;

    return _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap((snapshot) async {
      // consigue los ids de los usuarios bloqueados
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();

      // todos los usuarios
      final usersSnapshot = await _firestore.collection('Users').get();

      // retorna la lista excluyendo a los bloqueados
      final usersData = await Future.wait(
        // consigue todos los docs
        usersSnapshot.docs
            // elimina al usuario actual y los bloqueados
            .where((doc) =>
                doc.data()['email'] != currentUser.email &&
                !blockedUserIds.contains(doc.id))
            .map((doc) async {
          // revisa cada usuario
          final userData = doc.data();
          // y sus chats
          final chatRoomID = [currentUser.uid, doc.id]..sort();
          // y cuenta por chat los numeros de mensajjes sin leer
          final unreadMessagesSnapshot = await _firestore
              .collection("chat_rooms")
              .doc(chatRoomID.join('_'))
              .collection("messages")
              .where('receiverID', isEqualTo: currentUser.uid)
              .where('isRead', isEqualTo: false)
              .get();

          userData['unreadCount'] = unreadMessagesSnapshot.docs.length;
          return userData;
        }).toList(),
      );

      return usersData;
    });
  }
  // consigue la llave de encriptacion del chat, o la crea si no existe

  String shufle(String id){
    List<String> characters = id.split('');  // Convertir el string en una lista de caracteres
    characters.shuffle(Random());               // Mezclar la lista de caracteres
    return characters.join('');
  }

  Future<String> getOrMadeKey(String receiverID) async {
    String currentUserId = _auth.currentUser!.uid;
    List<String> ids = [currentUserId, receiverID];
    ids.sort(); // ordena los ids para que la llave de union sea identica
    String chatRoomID = ids.join('_'); 

    final oldkey = await _firestore.collection('Users')
        .doc(currentUserId)
        .collection('Keys')
        .doc(chatRoomID)
        .get();

    String key;
      
    if(oldkey.exists){
      key = oldkey.data()!["key"];
    }else{
      List<int> bytes = utf8.encode(chatRoomID);

      // Aplica SHA-256 para obtener el hash
      Digest sha256Digest = sha256.convert(bytes);

      // Convierte el hash en una cadena hexadecimal
      key = sha256Digest.toString();

      ChatKey chatKey = ChatKey(chatId: chatRoomID, key: key);
      await _firestore.collection('Users')
        .doc(currentUserId)
        .collection('Keys')
        .doc(chatRoomID).set(chatKey.toMap());
    }
     
    return key;
  }


  // Encripta el mensaje a enviar
  String encodeMessage(String key,String message){
     
      // transforma a su respectiva lista de bytes 
      List<int> codeKey = utf8.encode(key);
      List<int> codeMessage = utf8.encode(message);

      // realiza la operacion XOR para cada byte en el mensaje
      // si la llave es de menor longitud esta comenzara de nuevo.

      List<int> encryptedMessage = List<int>.generate(
        codeMessage.length,
        (i) => (codeMessage[i] ^ codeKey[i % codeKey.length])
      );

      //vuelve a texto el nuevo set de bytes

      String newMessage=utf8.decode(encryptedMessage);
      return newMessage;
  }




  // Enviar un mensaje
  Future<void> sendMessage(String receiverID, String message,String chatKey) async {
    // consigue la informacion actual del usuario
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();


    // construye el id del chat con el de lo dos usuarios
    List<String> ids = [currentUserID, receiverID];
    ids.sort(); // ordena los ids para que la llave de union sea identica
    String chatRoomID = ids.join('_'); // combina ambos en un string

    //consigue la llave de encriptacion

    String newMessage = encodeMessage(chatKey, message);

    // crea el mensaje nuevo
    Message sendMessage = Message(
      senderEmail: currentUserEmail,
      senderID: currentUserID,
      receiverID: receiverID,
      message: newMessage,
      timestamp: timestamp,
      isRead: false,
    );

    
    // add new messages to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(sendMessage.toMap());
  }

  // GET MESSAGE
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    // construct a chatroom ID for the two users
    List<String> ids = [userID, otherUserID];
    ids.sort(); // sort the ids (this ensures the chatroomID is the same for any 2 people)
    String chatRoomID = ids.join("_"); // combine into one string

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  // MARK MESSAGES AS READ
  Future<void> markMessagesAsRead(String receiverId) async {
    // get current user id
    final currentUserID = _auth.currentUser!.uid;

    // get chat room
    List<String> ids = [currentUserID, receiverId];
    ids.sort();
    String chatRoomID = ids.join('_');

    // get unread messages
    final unreadMessagesQuery = _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where('receiverID', isEqualTo: currentUserID)
        .where('isRead', isEqualTo: false);

    final unreadMessagesSnapshot = await unreadMessagesQuery.get();

    // go through each messages and mark as read
    for (var doc in unreadMessagesSnapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // REPORT USER
  Future<void> reportUser(String messageId, String userId) async {
    final currentUser = _auth.currentUser;
    final report = {
      'reportedBy': currentUser!.uid,
      'messageId': messageId,
      'messageOwnerId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('Reports').add(report);
  }

  // BLOCK USER
  Future<void> blockUser(String userId) async {
    final currentUser = _auth.currentUser;
    await _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .doc(userId)
        .set({});
    notifyListeners();
  }

  // UNBLOCK USER
  Future<void> unblockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;

    await _firestore
        .collection('Users')
        .doc(currentUser!.uid)
        .collection('BlockedUsers')
        .doc(blockedUserId)
        .delete();
  }

  // GET BLOCKED USERS STREAM
  Stream<List<Map<String, dynamic>>> getBlockedUsersStream(String userId) {
    return _firestore
        .collection('Users')
        .doc(userId)
        .collection('BlockedUsers')
        .snapshots()
        .asyncMap((snapshot) async {
      // get list of blocked user ids
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();

      final userDocs = await Future.wait(
        blockedUserIds
            .map((id) => _firestore.collection('Users').doc(id).get()),
      );

      // return as a list
      return userDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }
  
  
}
