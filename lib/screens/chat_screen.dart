import 'dart:io';
import 'package:appchat/screens/text_message.dart';
import 'text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return ChatScreenState();
  }
}

class ChatScreenState extends State<ChatScreen>{
  final CollectionReference _mensagens =
  FirebaseFirestore.instance.collection("mensagens");
  User? _currentUser;
  FirebaseAuth auth = FirebaseAuth.instance;
  final GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_currentUser  != null
              ? 'Olá, ${_currentUser?.email}'
              : "Chat App"),
          actions: <Widget>[
            _currentUser != null ?
            IconButton(onPressed: (){
              FirebaseAuth.instance.signOut();
              const snackBar = SnackBar(content: Text("Logout"),
                  backgroundColor: Colors.red);
            }, icon: Icon(Icons.exit_to_app))
                : Container()
          ],
          backgroundColor: Colors.cyan,
        ),
        body: Column(
          children: <Widget> [
            Expanded(child: StreamBuilder<QuerySnapshot>(
              stream: _mensagens.orderBy('time').snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState){
                  case ConnectionState.waiting :
                    return Center(child: CircularProgressIndicator());
                  default :
                    List<DocumentSnapshot> documents =
                    snapshot.data!.docs.reversed.toList();
                    return ListView.builder(
                      itemCount: documents.length,
                      reverse: true,
                      itemBuilder: (context, index){
                        return TextMessage(documents[index],
                            documents[index].get('uid') == _currentUser?.uid);
                      },
                    );
                }
              },
            )),
            _isLoading ? LinearProgressIndicator() : Container(),
            TextComposer(_sendMessage),
          ],
        )
    );
  }

  void _sendMessage({String? text, XFile? imgFile}) async {
    final CollectionReference _mensagens =
    FirebaseFirestore.instance.collection("mensagens");

    String id = "";
    User? user = await _getUser(context: context);
    if (user == null){
      const snackbar = SnackBar(content: Text("Não foi possível fazer login!"),
          backgroundColor: Colors.red);
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
      return;
    }

    setState((){
      _isLoading = true;
    });

    Map<String, dynamic> data = {
      'time' : Timestamp.now(),
      'url'  : '',
      'text' : '',
      'uid'  : user.uid,
      'senderName' : user.email,
      'senderPhotoUrl' : ''
    };

    if (user != null)
      id = user.uid;

    if (imgFile != null){ // chegou um arquivo de imagem
      firebase_storage.UploadTask uploadTask;
      firebase_storage.Reference ref =
      firebase_storage.FirebaseStorage.instance
          .ref()
          .child("imgs")
          .child(id+DateTime.now().millisecondsSinceEpoch.toString());
      final metadados = firebase_storage.SettableMetadata(
          contentType: "image/jpeg",
          customMetadata: {"picked-file-path" : imgFile.path}
      );
      if (kIsWeb){ // se estiver na plataforma WEB
        uploadTask = ref.putData(await imgFile.readAsBytes(), metadados);
      }else{  // se for outra plataforma
        uploadTask = ref.putFile(File(imgFile.path), metadados);
      }
      var taskSnapshot = await uploadTask;
      String imageUrl = "";
      imageUrl = await taskSnapshot.ref.getDownloadURL(); //URL da imagem no storage
      data['url'] = imageUrl;
    }else{ // se chegou apenas texto
      data['text'] = text;
    }
    _mensagens.add(data);
    setState((){
      _isLoading = false;
    });
  }

  Future<User?> _getUser({required BuildContext context}) async {
    if (_currentUser != null) return _currentUser;
    Navigator.pushReplacementNamed(context, '/login');
    return null;
  }

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }
}
