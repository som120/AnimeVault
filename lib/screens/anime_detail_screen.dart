import 'package:ainme_vault/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:shimmer/shimmer.dart';

class AnimeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> anime;

  const AnimeDetailScreen({super.key, required this.anime});

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isDarkStatusBar = true; // banner visible at start
  bool isLoading = true;
  bool isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setDarkStatusBar(); // white icons immediately
    });
    // Fake loading delay for smooth shimmer
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => isLoading = false);
    });
    // Listen to scroll
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    // If scrolled more than 100px → switch to light icons
    if (_scrollController.offset > 100 && isDarkStatusBar == true) {
      setState(() => isDarkStatusBar = false);
      _setLightStatusBar(); // black icons
    }
    // If near top → white icons
    else if (_scrollController.offset <= 100 && isDarkStatusBar == false) {
      setState(() => isDarkStatusBar = true);
      _setDarkStatusBar(); // white icons
    }
  }

  void _setDarkStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // white icons
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  void _setLightStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // black icons
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  Widget buildTopSection(BuildContext context, Map<String, dynamic> anime) {
    final poster = widget.anime['coverImage']?['large'];
    final banner = widget.anime['bannerImage'] ?? poster;
    final title = widget.anime['title']?['romaji'] ?? "Unknown";
    final subtitle = widget.anime['title']?['english'] ?? "";

    // Data preparation
    final format = widget.anime['format'] ?? "TV";
    final status = widget.anime['status']?.replaceAll("_", " ") ?? "N/A";
    final episodes = widget.anime['episodes']?.toString() ?? "?";
    final year = widget.anime['startDate']?['year']?.toString() ?? "----";

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
                              Colors.black.withOpacity(
                                0.2,
                              ), // Light dark at top
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
    final genres = widget.anime['genres'] ?? [];
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildDescription(Map<String, dynamic> anime) {
    final description =
        widget.anime['description']?.replaceAll(RegExp(r'<[^>]*>'), '') ??
        "No description available.";
    final isLong = description.length > 200;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Description",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            firstChild: Text(
              description,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            secondChild: Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            crossFadeState: isDescriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          if (isLong)
            GestureDetector(
              onTap: () {
                setState(() {
                  isDescriptionExpanded = !isDescriptionExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isDescriptionExpanded ? "View Less" : "View More",
                      style: const TextStyle(
                        color: Color(0xFF714FDC),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isDescriptionExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF714FDC),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (isLoading)
            const SingleChildScrollView(child: AnimeDetailShimmer())
          else
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  buildTopSection(context, widget.anime),
                  buildGenres(widget.anime),
                  buildDescription(widget.anime),
                ],
              ),
            ),

          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.5),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class AnimeDetailShimmer extends StatelessWidget {
  const AnimeDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner shimmer
          Container(
            height: 260,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
          ),

          const SizedBox(height: 140),

          // Poster shimmer (center)
          Center(
            child: Container(
              width: 210,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 20,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 16,
              width: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Info row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (i) => Column(
                  children: [
                    Container(
                      height: 14,
                      width: 40,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: 50,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // Genres shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              children: List.generate(
                4,
                (i) => Container(
                  height: 28,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // Description Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 20,
              width: 120,
              color: Colors.grey.shade300,
            ),
          ),

          const SizedBox(height: 15),

          // Description lines
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
