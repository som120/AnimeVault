import 'package:ainme_vault/utils/transitions.dart';
import 'package:flutter/material.dart';
import 'package:ainme_vault/screens/login_screen.dart';
import '../main.dart'; // import to access MainScreen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            SlideRightRoute(page: const MainScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F3FF),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ---------------------------
              // TOP CURVED GRADIENT CARD
              // ---------------------------
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8A5CF6), Color(0xFFC78BFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),

                  // Avatar
                  Positioned(
                    bottom: -60,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundImage: AssetImage("assets/avatar.png"),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 65), // Space for protruding avatar

              const Text(
                "User Name",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              // ---------------------------
              // STATS OVERVIEW
              // ---------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                ), // Smaller card width
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem("86.5", "Hours"),
                      _buildStatItem("340", "Completed"),
                      _buildStatItem("5", "Reviews"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 23),

              // ---------------------------
              // SETTINGS LIST
              // ---------------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                ), // Wider card
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        Icons.edit,
                        "Edit Profile",
                        context,
                        false,
                      ),
                      const SizedBox(height: 20),
                      _buildSettingsTile(
                        Icons.palette,
                        "Customize Avatar",
                        context,
                        false,
                      ),
                      const SizedBox(height: 20),
                      _buildSettingsTile(
                        Icons.dark_mode,
                        "Change Theme",
                        context,
                        false,
                      ),
                      const SizedBox(height: 20),
                      _buildSettingsTile(
                        Icons.settings,
                        "Account Settings",
                        context,
                        false,
                      ),
                      const SizedBox(height: 20),
                      _buildSettingsTile(Icons.logout, "Logout", context, true),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 35), // Same space as above the card
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // STAT ITEM WIDGET
  // ---------------------------
  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF8A5CF6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }

  // ---------------------------
  // SETTINGS TILE WIDGET
  // ---------------------------
  // ---------------------------
  // SETTINGS TILE WIDGET
  // ---------------------------
  Widget _buildSettingsTile(
    IconData icon,
    String title,
    BuildContext context,
    bool isDestructive,
  ) {
    return _ScaleButton(
      onTap: () {
        if (title == "Logout") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("$title tapped")));
        }
      },
      child: Container(
        color: Colors.transparent, // Ensures hit test works
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : const Color(0xFF8A5CF6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF8A5CF6),
                size: 25,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _ScaleButton({required this.onTap, required this.child});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
