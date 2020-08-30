import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Screens/login.dart';
import 'Widgets/const.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primaryColor: themeColor,
      ),
      home: LoginScreen(title: 'Chat App'),
      debugShowCheckedModeBanner: false,
    );
  }
}
