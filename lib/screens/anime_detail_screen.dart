import 'dart:async';
import 'package:ainme_vault/services/anilist_service.dart';
import 'package:ainme_vault/screens/character_detail_screen.dart';
import 'package:ainme_vault/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ainme_vault/screens/search_screen.dart';
import 'package:ainme_vault/utils/light_skeleton.dart';

class AnimeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> anime;

  const AnimeDetailScreen({super.key, required this.anime});

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool isDarkStatusBar = true; // banner visible at start
  bool isLoading = false;
  bool isDescriptionExpanded = false;
  int selectedTab = 0; // 0: Information, 1: Characters, 2: Relations
  late AnimationController _bannerAnimationController;
  late Animation<double> _bannerAnimation;
  late AnimationController _dotAnimationController;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    // Initialize banner animation
    _bannerAnimationController = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    );

    _bannerAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _bannerAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _bannerAnimationController.repeat(reverse: true);

    // Initialize pulsing dot animation
    _dotAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setDarkStatusBar(); // white icons immediately
    });

    _fetchAnimeDetails();

    // Listen to scroll
    _scrollController.addListener(_handleScroll);
  }

  Future<void> _fetchAnimeDetails() async {
    final id = widget.anime['id'];
    if (id == null) {
      setState(() => isLoading = false);
      return;
    }

    final details = await AniListService.getAnimeDetails(id);
    if (mounted) {
      setState(() {
        if (details != null) {
          // Merge details into existing anime map
          widget.anime.addAll(details);

          // Start countdown timer if anime is airing
          if (details['nextAiringEpisode'] != null) {
            _countdownTimer?.cancel();
            _countdownTimer = Timer.periodic(
              const Duration(seconds: 60),
              (_) => setState(() {}),
            );
          }
        }
      });
    }
  }

  void _handleScroll() {
    // Update status bar without setState to avoid rebuilds
    if (_scrollController.offset > 100 && isDarkStatusBar == true) {
      isDarkStatusBar = false;
      _setLightStatusBar(); // black icons
    } else if (_scrollController.offset <= 100 && isDarkStatusBar == false) {
      isDarkStatusBar = true;
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
            RepaintBoundary(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _bannerAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _bannerAnimation.value,
                        child: child,
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: banner,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => LightSkeleton(
                            width: double.infinity,
                            height: 260,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ⭐ POSTER OVERLAP
            Positioned(
              bottom: -170,
              left: 0,
              right: 0,
              child: Center(
                child: RepaintBoundary(
                  child: Container(
                    width: 210,
                    height: 300,
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
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: poster,
                            height: 300,
                            width: 210,
                            fit: BoxFit.cover,
                            memCacheWidth: 420,
                            memCacheHeight: 600,
                            placeholder: (context, url) => LightSkeleton(
                              width: 210,
                              height: 300,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        // Green pulsing dot for airing anime (bottom right)
                        if (widget.anime['status'] == 'RELEASING')
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _dotAnimationController,
                                builder: (context, child) {
                                  final value = _dotAnimationController.value;
                                  // Create a second staggered wave
                                  final value2 = (value >= 0.5)
                                      ? value - 0.5
                                      : value + 0.5;

                                  return SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // First Ripple Ring
                                        if (value < 0.95)
                                          Container(
                                            width: 12 + (value * 20),
                                            height: 12 + (value * 20),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Color.fromRGBO(
                                                  105,
                                                  240,
                                                  174,
                                                  (1.0 - value) * 0.8,
                                                ),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                        // Second Ripple Ring (Staggered)
                                        if (value2 < 0.95)
                                          Container(
                                            width: 12 + (value2 * 20),
                                            height: 12 + (value2 * 20),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Color.fromRGBO(
                                                  105,
                                                  240,
                                                  174,
                                                  (1.0 - value2) * 0.8,
                                                ),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                        // Center Dot (const child)
                                        child!,
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF69F0AE),
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x9969F0AE),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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

        const SizedBox(height: 10),
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

  Widget buildStatsCard(Map<String, dynamic> anime) {
    final score = anime['averageScore']?.toString() ?? "N/A";
    final popularity = anime['popularity'] != null
        ? _formatNumber(anime['popularity'])
        : "N/A";

    // Try to find "Rated" rank (all time)
    String rank = "N/A";

    if (anime['status'] != 'NOT_YET_RELEASED') {
      final rankings = anime['rankings'] as List?;
      if (rankings != null) {
        final rated = rankings.firstWhere(
          (r) => r['type'] == 'RATED' && r['allTime'] == true,
          orElse: () => null,
        );
        if (rated != null) {
          rank = "#${rated['rank']}";
        } else {
          // Fallback to favourites if no rank found
          final favs = anime['favourites'];
          if (favs != null) {
            rank = _formatNumber(favs); // Show hearts count instead
          }
        }
      }
    }

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              Icons.star_rounded,
              Colors.amber,
              "$score%",
              "Score",
            ),
            _buildStatItem(
              Icons.favorite_rounded,
              Colors.pinkAccent,
              popularity,
              "Popular",
            ),
            _buildStatItem(
              Icons.emoji_events_rounded,
              Colors.blueAccent,
              rank,
              "Rank",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return "${(number / 1000000).toStringAsFixed(1)}M";
    }
    if (number >= 1000) {
      return "${(number / 1000).toStringAsFixed(1)}k";
    }
    return number.toString();
  }

  Widget buildGenres(Map<String, dynamic> anime) {
    final genres = (anime['genres'] as List?) ?? [];
    if (genres.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: genres.map<Widget>((genre) {
              return GestureDetector(
                onTap: () {
                  // AniList API genres are case-sensitive and returned in Title Case
                  // (e.g., "Action", "Comedy", "Sci-Fi")
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          SearchScreen(initialGenre: genre.toString().trim()),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, 1.0);
                            const end = Offset.zero;
                            const curve = Curves.easeOutCubic;

                            var tween = Tween(
                              begin: begin,
                              end: end,
                            ).chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingSites(Map<String, dynamic> anime) {
    final externalLinks = anime['externalLinks'] as List?;
    if (externalLinks == null) return const SizedBox.shrink();

    final streamingLinks = externalLinks
        .where((link) => link['type'] == 'STREAMING')
        .toList();

    if (streamingLinks.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Streaming Sites",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: streamingLinks.map<Widget>((link) {
                final site = link['site'] ?? "Unknown";
                final url = link['url'];
                final colorHex = link['color'];
                Color color;
                if (colorHex != null) {
                  try {
                    color = Color(
                      int.parse(colorHex.substring(1), radix: 16) + 0xFF000000,
                    );
                  } catch (e) {
                    color = AppTheme.primary;
                  }
                } else {
                  color = AppTheme.primary;
                }

                return GestureDetector(
                  onTap: () async {
                    if (url != null) {
                      final uri = Uri.parse(url);
                      try {
                        if (!await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        )) {
                          debugPrint("Could not launch $url");
                        }
                      } catch (e) {
                        debugPrint("Error launching URL: $e");
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          site,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.open_in_new, size: 14, color: color),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabsContainer(Map<String, dynamic> anime) {
    return RepaintBoundary(
      child: Column(
        children: [
          // Tab Buttons
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                _buildTabButton("Information", 0),
                _buildTabButton("Characters", 1),
                _buildTabButton("Relations", 2),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab Content - Enhanced morphing animation
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0.0, 0.05),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: child,
                          ),
                        );
                      },
                  child: _buildTabContent(anime),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.primary : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> anime) {
    switch (selectedTab) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('info'),
          child: _buildInformationTab(anime),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('chars'),
          child: _buildCharactersTab(anime),
        );
      case 2:
        return KeyedSubtree(
          key: const ValueKey('rels'),
          child: _buildRelationsTab(anime),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInformationTab(Map<String, dynamic> anime) {
    final studios = anime['studios']?['nodes'] as List?;
    final trailer = anime['trailer'];
    final studioName = (studios != null && studios.isNotEmpty)
        ? studios.first['name']
        : "Unknown";
    final screenWidth = MediaQuery.of(context).size.width;
    final double videoWidth = screenWidth > 420
        ? 360 // cap width on large phones / XL
        : screenWidth - 80; // normal phones

    // Date Formatting Helper
    String formatDate(Map<String, dynamic>? date) {
      if (date == null || date['year'] == null) return "?";
      final year = date['year'];
      final month = date['month'];
      final day = date['day'];
      if (month == null || day == null) return "$year";
      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      return "${months[month - 1]} $day, $year";
    }

    final startDate = formatDate(anime['startDate']);
    final endDate = formatDate(anime['endDate']);
    final season = anime['season'] != null
        ? "${anime['season'][0].toUpperCase()}${anime['season'].substring(1).toLowerCase()} ${anime['seasonYear'] ?? ''}"
        : "Unknown";
    final sourceRaw = anime['source']?.replaceAll('_', ' ') ?? "Unknown";
    final source = sourceRaw.isNotEmpty
        ? "${sourceRaw[0].toUpperCase()}${sourceRaw.substring(1).toLowerCase()}"
        : "Unknown";
    final duration = anime['duration'] != null
        ? "${anime['duration']} mins"
        : "Unknown";

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Details Rows
          _buildDetailRow("Duration", duration, Icons.schedule_rounded),
          _buildDetailRow(
            "Start Date",
            startDate,
            Icons.calendar_today_rounded,
          ),
          _buildDetailRow("End Date", endDate, Icons.event_rounded),
          _buildDetailRow("Season", season, Icons.calendar_month_rounded),
          _buildDetailRow("Source", source, Icons.local_offer_rounded),

          const SizedBox(height: 10),
          Divider(color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 10),

          // Studio
          // Studio
          Row(
            children: [
              Icon(
                Icons.movie_creation_rounded,
                size: 20,
                color: AppTheme.primary.withOpacity(0.75),
              ),
              const SizedBox(width: 8),
              Text(
                "Studio",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              studioName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          // Trailer Section
          if (trailer != null && trailer['site'] == 'youtube') ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  size: 20,
                  color: AppTheme.primary.withOpacity(0.75),
                ),
                const SizedBox(width: 8),
                Text(
                  "Trailer",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Trailer Banner
            Center(
              child: SizedBox(
                width: videoWidth,
                child: GestureDetector(
                  onTap: () async {
                    final url = Uri.parse(
                      'https://www.youtube.com/watch?v=${trailer['id']}',
                    );
                    try {
                      if (!await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      )) {
                        throw 'Could not launch $url';
                      }
                    } catch (e) {
                      debugPrint("Error launching URL: $e");
                    }
                  },
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                                'https://img.youtube.com/vi/${trailer['id']}/hqdefault.jpg',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => LightSkeleton(
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            ),
                            fadeInDuration: const Duration(milliseconds: 150),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary.withOpacity(0.75)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharactersTab(Map<String, dynamic> anime) {
    final characters = anime['characters']?['edges'] as List?;
    // Show loading indicator if characters are not yet loaded (null) but not empty list (explicitly no chars)
    // Actually API returns null if not fetched yet, empty list if fetched but none.
    // However, since we initialize with basic data, 'characters' key might be missing entirely.
    if (characters == null && widget.anime['characters'] == null) {
      return const SizedBox(
        height: 175,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (characters == null || characters.isEmpty) {
      return const Center(child: Text("No characters found"));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 5),

      child: SizedBox(
        height: 180, // Increased height to fix overflow
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: characters.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final edge = characters[index];
            final node = edge['node'];
            String role = edge['role']?.toString() ?? "Unknown";
            role = role.isNotEmpty
                ? role[0].toUpperCase() + role.substring(1).toLowerCase()
                : "Unknown";

            if (node == null) return const SizedBox.shrink();

            final name = node['name']?['full'] ?? "Unknown";
            final image = node['image']?['medium'];
            final id = node['id'];

            return GestureDetector(
              onTap: () {
                if (id != null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.6,
                      minChildSize: 0.4,
                      maxChildSize: 1.0,
                      builder: (context, scrollController) {
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: CharacterDetailScreen(
                            characterId: id,
                            placeholderName: name,
                            placeholderImage: image,
                            scrollController: scrollController,
                          ),
                        );
                      },
                    ),
                  );
                }
              },
              child: SizedBox(
                width: 130, // Increased width
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.20),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: image,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => LightSkeleton(
                            width: 120,
                            height: 120,
                            borderRadius: BorderRadius.circular(60),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person),
                          ),
                          fadeInDuration: const Duration(milliseconds: 150),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRelationsTab(Map<String, dynamic> anime) {
    final relations = anime['relations']?['edges'] as List?;

    if (relations == null && widget.anime['relations'] == null) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (relations == null || relations.isEmpty) {
      return const Center(child: Text("No relations found"));
    }

    // Filter out invalid nodes
    final validRelations = relations
        .where((edge) => edge['node'] != null)
        .toList();
    if (validRelations.isEmpty) {
      return const Center(child: Text("No relations found"));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: SizedBox(
        height: 220,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: validRelations.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          separatorBuilder: (context, index) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final edge = validRelations[index];
            final node = edge['node'];
            String relationType =
                edge['relationType']?.replaceAll('_', ' ') ?? 'Related';
            // Convert to Title Case
            relationType = relationType
                .split(' ')
                .map((str) {
                  if (str.isEmpty) return str;
                  return str[0].toUpperCase() + str.substring(1).toLowerCase();
                })
                .join(' ');

            final title =
                node['title']?['romaji'] ??
                node['title']?['english'] ??
                'Unknown';
            final image =
                node['coverImage']?['large'] ?? node['coverImage']?['medium'];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnimeDetailScreen(anime: node),
                  ),
                );
              },
              child: SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image != null
                        ? FadeInImageWidget(
                            imageUrl: image,
                            width: 110,
                            height: 155,
                          )
                        : Container(
                            width: 110,
                            height: 155,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                    const SizedBox(height: 6),
                    Text(
                      relationType,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildRecommendations(Map<String, dynamic> anime) {
    final recommendations = anime['recommendations']?['nodes'] as List?;
    if (recommendations == null || recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final validRecs = recommendations
        .where((node) => node['mediaRecommendation'] != null)
        .take(20)
        .toList();

    if (validRecs.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recommendations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 215, // Increased height
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: validRecs.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                separatorBuilder: (context, index) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final rec = validRecs[index];
                  final media = rec['mediaRecommendation'];
                  final title =
                      media['title']?['romaji'] ??
                      media['title']?['english'] ??
                      "Unknown";
                  final image =
                      media['coverImage']?['large'] ??
                      media['coverImage']?['medium'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeDetailScreen(anime: media),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 120, // Increased width
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          image != null
                              ? FadeInImageWidget(
                                  imageUrl: image,
                                  width: 120,
                                  height: 170,
                                )
                              : Container(
                                  width: 120,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.grey,
                                  ),
                                ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2, // Allow 2 lines for better readability
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDescription(Map<String, dynamic> anime) {
    final description =
        widget.anime['description']?.replaceAll(RegExp(r'<[^>]*>'), '') ??
        "No description available.";
    final isLong = description.length > 200;

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        // Increased padding to narrow text width and add breathing room
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
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
            // More vertical padding between title and text
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                if (isLong) {
                  setState(() {
                    isDescriptionExpanded = !isDescriptionExpanded;
                  });
                }
              },
              child: AnimatedCrossFade(
                firstChild: Text(
                  description,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5, // Softer line-height
                  ),
                ),
                secondChild: Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.5, // Softer line-height
                  ),
                ),
                crossFadeState: isDescriptionExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ),
            if (isLong)
              GestureDetector(
                onTap: () {
                  setState(() {
                    isDescriptionExpanded = !isDescriptionExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: Icon(
                      isDescriptionExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded, // Chevron arrow
                      color: const Color(0xFF714FDC),
                      size: 24, // Slightly larger for emphasis
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Stack(
          key: ValueKey(isLoading),
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  buildTopSection(context, widget.anime),
                  buildStatsCard(widget.anime),
                  _buildNextEpisodeWidget(widget.anime),
                  buildGenres(widget.anime),
                  buildDescription(widget.anime),
                  const SizedBox(height: 10),
                  buildTabsContainer(widget.anime),
                  _buildStreamingSites(widget.anime),
                  buildRecommendations(widget.anime),
                  const SizedBox(height: 30), // Bottom padding
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
      ),
    );
  }

  Widget _buildNextEpisodeWidget(Map<String, dynamic> anime) {
    if (anime['status'] != 'RELEASING' || anime['nextAiringEpisode'] == null) {
      return const SizedBox.shrink();
    }

    final nextEp = anime['nextAiringEpisode'];
    final airingAt = nextEp['airingAt'] as int;
    final firingDate = DateTime.fromMillisecondsSinceEpoch(airingAt * 1000);
    final now = DateTime.now();
    final diff = firingDate.difference(now);

    if (diff.isNegative) return const SizedBox.shrink();

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, color: AppTheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ep ${nextEp['episode']} Airing In",
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${days}d ${hours}h ${minutes}m",
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollController.dispose();
    _bannerAnimationController.dispose();
    _dotAnimationController.dispose();
    super.dispose();
  }
}


class FadeInImageWidget extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;

  const FadeInImageWidget({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          memCacheWidth: (width * 3).toInt(), // Optimize decoding size
          placeholder: (context, url) => Container(color: Colors.grey[200]),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
          fadeInDuration: const Duration(milliseconds: 250),
        ),
      ),
    );
  }
}
