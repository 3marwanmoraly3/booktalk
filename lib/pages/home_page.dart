import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_page.dart';
import 'categories_page.dart';
import 'profile_page.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    HomeScreen(),
    SearchPage(),
    const CategoriesPage(),
    const ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: Color(0xff1B073B),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'BookTalk',
              style: TextStyle(
                  color: Color(0xff6255FA),
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color(0xffDCE9FF),
          ),
          backgroundColor: Color(0xffDCE9FF),
          body: _tabs[_currentIndex],
          bottomNavigationBar: SizedBox(
            height: 80,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              child: BottomNavigationBar(
                iconSize: 32,
                selectedItemColor: Colors.white,
                currentIndex: _currentIndex,
                unselectedItemColor: Colors.white30,
                backgroundColor: Color(0xff1B073B),
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                onTap: (int index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search_rounded),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.category_rounded),
                    label: 'Categories',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.account_circle),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
