import 'package:flutter/material.dart';
import 'package:stylemate/utils/constants.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppConstants.background,
      selectedItemColor: AppConstants.primaryAccent,
      unselectedItemColor: Colors.black54,
      elevation: 10,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.checkroom_rounded), label: "Closet"),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: "Outfit"),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: "Analytics"),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
      ],
    );
  }
}
