import 'dart:ui';

import 'package:ainme_vault/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

import 'package:flutter_displaymode/flutter_displaymode.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/profile_screen.dart';
//import 'firestore_test_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {
    // Ignore errors if platform doesn't support it
  }

  runApp(const AnimeVaultApp());
}

class AnimeVaultApp extends StatelessWidget {
  const AnimeVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniVault',
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  double scrollOpacity = 0.18;

  DateTime? _lastBackPressTime;
  late SharedPreferences _prefs;

  // Screens used in bottom navigation
  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];
  Widget navItem(IconData icon, String label, int index) {
    bool active = _currentIndex == index;

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: active ? 1.15 : 1.0, // BOUNCE ANIMATION
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () async {
            setState(() => _currentIndex = index);
            await _prefs.setInt('last_tab', index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: active
                  ? const Color(0xFF714FDC).withOpacity(0.2)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: active ? 22 : 24,
                  color: active ? const Color(0xFF714FDC) : Colors.white,
                ),
                if (active) ...[
                  const SizedBox(height: 2),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF714FDC),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastTab();
  }

  Future<void> _loadLastTab() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIndex = _prefs.getInt('last_tab') ?? 0;
    });
  }

  Future<bool> _handleBackPress() async {
    // If not on Home → go to Home
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      await _prefs.setInt('last_tab', 0);
      return false;
    }

    final now = DateTime.now();

    // First back press
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text("Press back again to exit"),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

      return false; // ⛔ don’t exit yet
    }

    // Second back press within 2 seconds → EXIT
    await SystemNavigator.pop();
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force rebuild so BackdropFilter reapplies blur
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          body: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),

              // Bottom progressive fade blur
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 80,
                child: IgnorePointer(
                  ignoring: true, // allows touches to pass through
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white12,
                          Colors.white60, // subtle fade
                          Colors.white, // full fade under nav bar
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Rounded Nav Bar
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            0.18,
                          ), // transparent glass
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withOpacity(
                              0.5,
                            ), // glass border
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF714FDC,
                              ).withOpacity(0.2), // purple glow
                              blurRadius: 25,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            navItem(Icons.home_rounded, "Home", 0),
                            navItem(Icons.search_rounded, "Search", 1),
                            navItem(Icons.person_rounded, "Profile", 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
