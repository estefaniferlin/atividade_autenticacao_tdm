import 'package:appchat/screens/chat_screen.dart';
import 'package:appchat/screens/login_screen.dart';
import 'package:appchat/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:appchat/screens/chat_screen.dart';
import 'package:appchat/screens/login_screen.dart';
import 'menu.dart';
import 'package:appchat/screens/register_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: NavigationOptions(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/chat': (context) => ChatScreen(),
      },
    );
  }
}
