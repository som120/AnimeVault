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

    final format = anime['format'] ?? "TV";
    final status = anime['status']?.replaceAll("_", " ") ?? "N/A";
    final episodes = anime['episodes']?.toString() ?? "N/A";
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
                    // Blur Effect
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(color: Colors.black.withOpacity(0.2)),
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

        // Enough space for the poster to overlap
        const SizedBox(height: 180),

        // ⭐ TITLE
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        if (subtitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildInfoBox("Format", format),
              buildInfoBox("Status", status),
              buildInfoBox("Episodes", episodes),
              buildInfoBox("Year", year),
            ],
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // Reusable small info box
  Widget buildInfoBox(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
        spacing: 8,
        runSpacing: 8,
        children: genres.map<Widget>((genre) {
          return Chip(
            label: Text(genre),
            backgroundColor: const Color(0xFFEDE7FF),
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          );
        }).toList(),
      ),
    );
  }

  Widget buildDescription(Map<String, dynamic> anime) {
    final description = anime['description'] ?? "No description available.";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Description",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description.replaceAll(RegExp(r'<[^>]*>'), ''), // Remove HTML tags
            style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Wrap whole page in a Stack
      body: Stack(
        children: [
          // ============================
          // MAIN SCROLLABLE CONTENT
          // ============================
          SingleChildScrollView(
            child: Column(
              children: [
                buildTopSection(context, anime),
                buildGenres(anime),
                buildDescription(anime),
              ],
            ),
          ),

          // ============================
          // FIXED BACK BUTTON (NOT SCROLLING)
          // ============================
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: AppTheme.accent.withOpacity(0.35),
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
