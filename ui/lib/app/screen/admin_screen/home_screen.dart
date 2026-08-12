import 'package:flutter/material.dart';

import '../login_screen.dart';
import '../profile_screen.dart';
import 'subject_class_screen.dart';
import '../../../features/auth/api.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [_buildHomeScreen(), const SubjectClassScreen(), const ProfileScreen()];
  }

  void _handleLogout() async {
    await ApiService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (_isSelectionMode) {
              _isSelectionMode = false;
              _selectedIds.clear();
            }
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Subject Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Trang chủ của Quản trị viên', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (){
              _handleLogout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}