import 'package:ainme_vault/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class AnimeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> anime;

  const AnimeDetailScreen({super.key, required this.anime});

  Widget buildTopSection(BuildContext context, Map<String, dynamic> anime) {
    final poster = anime['coverImage']?['large'];
    final banner = anime['bannerImage'] ?? poster;
    final title = anime['title']?['romaji'] ?? "Unknown";
    final subtitle = anime['title']?['english'] ?? "";

    // Data preparation
    final format = anime['format'] ?? "TV";
    final status = anime['status']?.replaceAll("_", " ") ?? "N/A";
    final episodes = anime['episodes']?.toString() ?? "?";
    final year = anime['startDate']?['year']?.toString() ?? "----";

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // 🌈 BANNER
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(banner),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // 2. Blur + Linear Gradient Overlay
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.2), // Light dark at top
                              Colors.black.withOpacity(0.7), // Darker at bottom
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                    ),
                    
                  ],
                ),
              ),
            ),

            // ⭐ POSTER OVERLAP
            Positioned(
              bottom: -170,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      poster,
                      height: 300,
                      width: 210,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Space for the poster overlap
        const SizedBox(height: 180),

        // ⭐ TITLE
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),

        // ⭐ SUBTITLE
        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 20, right: 20),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),

        const SizedBox(height: 24),

        // INFO CARD
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildStatColumn("Format", format),
              buildStatColumn("Status", _formatStatus(status)),
              buildStatColumn("Episodes", episodes),
              buildStatColumn("Year", year),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // Helper to title-case the status (e.g., "FINISHED" -> "Finished")
  String _formatStatus(String status) {
    if (status.isEmpty) return "N/A";
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  // Widget for a single column in the info card
  Widget buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold, // Bold label (Top row)
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600, // Grey value (Bottom row)
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
 

  Widget buildGenres(Map<String, dynamic> anime) {
    final genres = anime['genres'] ?? [];
    if (genres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: genres.map<Widget>((genre) {
          return Chip(
            label: Text(genre),
            backgroundColor: const Color(0xFF714FDC).withOpacity(0.05),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF714FDC),
            ),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        }).toList(),
      ),
    );
  }

  Widget buildDescription(Map<String, dynamic> anime) {
    final description = anime['description'] ?? "No description available.";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Description",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description.replaceAll(RegExp(r'<[^>]*>'), ''), // Remove HTML tags
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Make sure background is white for shadow contrast
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                buildTopSection(context, anime),
                buildGenres(anime),
                buildDescription(anime),
                const SizedBox(height: 50),
              ],
            ),
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor:  AppTheme.primary.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}