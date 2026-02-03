import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() {
  runApp(const PegaRansomApp());
}

class PegaRansomApp extends StatelessWidget {
  const PegaRansomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PegaRansom',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
