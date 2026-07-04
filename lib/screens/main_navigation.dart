import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'campaign_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // List halaman diurutkan sesuai urutan tombol di bottom navigation
  final List<Widget> _screens = [
    const DashboardScreen(), // Index 0
    const CampaignScreen(), // Index 1
    const HistoryScreen(), // Index 2
    const ProfileScreen(), // Index 3
  ];

  // Kumpulan judul AppBar dinamis mengikuti screen yang aktif
  final List<String> _titles = [
    'Dashboard Analytic',
    'Program Campaign',
    'Riwayat Transaksi',
    'Profil Pengguna',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
      ),
      // PERBAIKAN DI SINI: Mengubah IndexedStack menjadi rendering dinamis langsung.
      // Ini memastikan initState() di setiap screen dipicu ulang untuk Get API baru saat tab berpindah.
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism),
            label: 'Campaign',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
