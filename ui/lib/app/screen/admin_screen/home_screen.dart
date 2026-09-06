import 'package:flutter/material.dart';
import '../login_screen.dart';
import '../profile_screen.dart';
import 'subject_class_screen.dart';
import 'exam_screen.dart';
import 'schedule_screen.dart';
import '../../../features/auth/api.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _buildHomeScreen(), 
      const SubjectClassScreen(), 
      const ExamScreen(), 
      const ScheduleScreen(),
      const ProfileScreen()
    ];
  }

  void _handleLogout() async {
    await ApiService.logout();
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hệ Thống Quản Trị'),
        backgroundColor: const Color(0xFF6E8CF0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF6E8CF0),
              ),
              accountName: const Text(
                'Quản trị viên', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              accountEmail: const Text('Admin Dashboard'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: const Color(0xFF6E8CF0),
                  size: 40,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    title: 'Trang chủ',
                    index: 0,
                  ),
                  _buildDrawerItem(
                    icon: Icons.class_outlined,
                    activeIcon: Icons.class_,
                    title: 'Lớp học phần',
                    index: 1,
                  ),
                  _buildDrawerItem(
                    icon: Icons.event_note_outlined,
                    activeIcon: Icons.event_note,
                    title: 'Lịch thi',
                    index: 2,
                  ),
                  _buildDrawerItem(
                    icon: Icons.calendar_month_outlined,
                    activeIcon: Icons.calendar_month,
                    title: 'Thời gian biểu',
                    index: 3,
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    title: 'Hồ sơ',
                    index: 4,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        isSelected ? activeIcon : icon,
        color: isSelected ? const Color(0xFF6E8CF0) : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF6E8CF0) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF6E8CF0).withValues(alpha: 0.1),
      onTap: () => _onItemTapped(index),
    );
  }

  Widget _buildHomeScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.admin_panel_settings, size: 80, color: Color(0xFF6E8CF0)),
          const SizedBox(height: 16),
          const Text('Trang chủ của Quản trị viên', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          const Text('Vui lòng mở menu bên trái để điều hướng.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}