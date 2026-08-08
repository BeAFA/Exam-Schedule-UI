// main.dart
import 'package:flutter/material.dart';
import 'app/router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý đăng ký môn học',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AppRouter.initialScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}