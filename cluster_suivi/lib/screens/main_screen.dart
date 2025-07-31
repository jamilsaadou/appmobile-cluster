import 'package:flutter/material.dart';
import 'sites_screen.dart';
import 'activities_screen.dart';
import 'sync_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SitesScreen(),
    const ActivitiesScreen(),
    const SyncScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'Sites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Activités',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sync),
            label: 'Synchronisation',
          ),
        ],
      ),
    );
  }
}