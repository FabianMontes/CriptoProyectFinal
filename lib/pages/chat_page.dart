import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../components/chat_bubble.dart';
import '../components/my_textfield.dart';
import '../services/auth/auth_service.dart';
import '../services/chat/chat_service.dart';
import 'home_page.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  final String keyy;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
    required this.keyy,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  
  bool cripted = false;


  // le da focus al textfield
  FocusNode myFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        print("TextField has focus");

        // el delay del teclado 
        Future.delayed(const Duration(milliseconds: 500), () {
          _scrollDown();
        });
      } else {
        print("TextField has lost focus");
      }
    });

    // espera a que la lista se genere
    Future.delayed(const Duration(milliseconds: 500), () {
      _scrollDown();
    });
  }

  @override
  void dispose() {
    // Limpia el nodo de focus
    myFocusNode.dispose();
    super.dispose();
  }

  void criptidMessages(){
    cripted = !cripted;
  }
  
  void sendMessage() async {
    // revisar que exista algo que enviar
    if (_messageController.text.isNotEmpty) {
      // enviar el mensaje
      await _chatService.sendMessage(
          widget.receiverID, _messageController.text,widget.keyy);
      // clear text controller
      _messageController.clear();
    }

    _scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.receiverEmail,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            // navigate to homepage and remove all previous routes
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(),
                ),
                // keep the first route (Auth Gate)
                (route) => route.isFirst);
          },
        ),
        actions:[ IconButton(
          icon: Icon(
            cripted ? Icons.vpn_key_off:Icons.vpn_key,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            setState(() {
              criptidMessages();
            });
          },
        ),]
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          // all messages
          Expanded(
            child: _buildMessageList(cripted),
          ),

          // user input
          _buildUserInput()
        ],
      ),
    );
  }

  // scroll controller
  final ScrollController _controller = ScrollController();

  void _scrollDown() {
    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  // build message list
  Widget _buildMessageList(bool cripted) {
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverID, senderID),
      builder: (context, snapshot) {
        // errors
        if (snapshot.hasError) {
          return Text('Error${snapshot.error}');
        }

        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading..");
        }

        // list view
        return ListView(
          controller: _controller,
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc,cripted,widget.keyy)).toList(),
        );
      },
    );
  }

  // build message item
  Widget _buildMessageItem(DocumentSnapshot doc,bool cripted,String key) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    var message = cripted ? data["message"] : _chatService.encodeMessage(key, data["message"]);

    // is current user
    bool isCurrentUser = data['senderID'] == _authService.getCurrentUser()!.uid;

    // align message to the right if sender is the current user, otherwise left
    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            message:message,
            isCurrentUser: isCurrentUser,
            messageId: doc.id,
            userId: data["senderID"],
          ),
        ],
      ),
    );
  }

  // build message input
  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: Row(
        children: [
          // textfield should take up most of the space
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: "Type a message",
              obscureText: false,
              focusNode: myFocusNode,
            ),
          ),

          // send button
          Container(
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 25),
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}
