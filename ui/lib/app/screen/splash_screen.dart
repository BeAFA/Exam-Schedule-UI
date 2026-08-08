import 'package:flutter/material.dart';
import '../../core/token_storage.dart';
import 'login_screen.dart';
import 'student_screen/home_screen.dart';
import 'teacher_screen/home_screen.dart';
import 'admin_screen/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final token = await TokenStorage.getToken();
    final role = await TokenStorage.getRole();

    if (!mounted) return;

    Widget target;
    if (token == null || role == null) {
      target = const LoginScreen();
    } else {
      target = switch (role) {
        'STUDENT' => const StudentHomeScreen(),
        'TEACHER' => const TeacherHomeScreen(),
        'ADMIN' => const AdminHomeScreen(),
        _ => const LoginScreen(),
      };
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}