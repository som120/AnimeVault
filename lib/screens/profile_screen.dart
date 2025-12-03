import 'package:ainme_vault/utils/transitions.dart';
import 'package:flutter/material.dart';
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
                children: [
                  Container(
                    height: 260,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8A5CF6), Color(0xFFC78BFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),

                  // Avatar + Username
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 44,
                            backgroundImage: AssetImage(
                              "assets/avatar.png", // your avatar file path
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "User Name",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ---------------------------
              // STATS OVERVIEW
              // ---------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard("86.5", "Hours"),
                    _buildStatCard("340", "Completed"),
                    _buildStatCard("5", "Reviews"),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // ---------------------------
              // SETTINGS LIST
              // ---------------------------
              _buildSettingsTile(Icons.edit, "Edit Profile", context),
              _buildSettingsTile(Icons.brush, "Customize Avatar", context),
              _buildSettingsTile(Icons.brightness_6, "Change Theme", context),
              _buildSettingsTile(Icons.settings, "Account Settings", context),
              _buildSettingsTile(Icons.logout, "Logout", context),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------
  // STAT CARD WIDGET
  // ---------------------------
  Widget _buildStatCard(String value, String label) {
    return Container(
      height: 90,
      width: 105,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8A5CF6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // SETTINGS TILE WIDGET
  // ---------------------------
  Widget _buildSettingsTile(IconData icon, String title, BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Color(0xFF8A5CF6), size: 26),
          title: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
          onTap: () {
            // Placeholder navigation, you can update these later
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("$title tapped")));
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1),
        ),
      ],
    );
  }
}
