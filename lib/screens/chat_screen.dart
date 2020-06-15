import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore=Firestore.instance;

class ChatScreen extends StatefulWidget {
  static const routeName = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  FirebaseUser currentUser;
  String message;
  final messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    message = '';
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser();
      if (user != null) {
        currentUser = await user;
        print(currentUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

//  void getMessages() async {
//    var docs = await _firestore.collection('messages').getDocuments();
//    for(var doc in docs.documents){
//      print(doc.data);
//    }
//  }

//  void getStream() async {
//    await for (var snapshot in _firestore.collection('messages').snapshots()) {
//      for (var message in snapshot.documents) {
//        print(message.data);
//      }
//    }
//  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                try {
                  _auth.signOut();
                  print('loggedOut');
                  Navigator.pop(context);
                } catch (e) {
                  print(e);
                }
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(currentUser: currentUser,),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onChanged: (value) {
                        message = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () async {
                        await _firestore.collection('messages').add({
                        'message': this.message,
                        'sender': currentUser.email,
                      });
                        messageController.clear();
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {

  FirebaseUser currentUser;
  MessagesStream({this.currentUser});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(
            backgroundColor: Colors.lightBlue,
          );
        }
        final docs = snapshot.data.documents.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var doc in docs) {
          final m = doc['message'];
          final sender = doc['sender'];
          Widget messageBubble = MessageBubble(
            sender: sender,
            message: m,
            currentUser: this.currentUser,
          );
          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}


class MessageBubble extends StatelessWidget {
  String sender;
  String message;
  FirebaseUser currentUser;

  MessageBubble({this.sender, this.message, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Align(
            alignment: currentUser.email!=sender ? Alignment.centerLeft : Alignment.centerRight,
            child: Text(
              sender,
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          Align(
            alignment: currentUser.email!=sender ? Alignment.centerLeft : Alignment.centerRight,
            child: Material(
              elevation: 5,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                topLeft: currentUser.email==sender ? Radius.circular(30) : Radius.circular(0),
                  topRight: currentUser.email==sender ? Radius.circular(0) : Radius.circular(30),
                bottomRight: Radius.circular(30)
              ),
              color: currentUser.email==sender ? Colors.blueAccent : Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  message,
                  style: TextStyle(fontSize: 15,
                      color: currentUser.email==sender ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
