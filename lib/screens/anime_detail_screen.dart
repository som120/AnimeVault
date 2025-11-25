import 'package:ainme_vault/services/anilist_service.dart';
import 'package:ainme_vault/screens/character_detail_screen.dart';
import 'package:ainme_vault/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

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
  int selectedTab = 0; // 0: Information, 1: Characters, 2: Relations

  @override
  void initState() {
    super.initState();
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
        }
        isLoading = false;
      });
    }
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

    return Container(
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
          _buildStatItem(Icons.star_rounded, Colors.amber, "$score%", "Score"),
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
    final genres = anime['genres'] ?? [];
    if (genres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Genres",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Wrap(
            alignment: WrapAlignment.start,
            spacing: 10,
            runSpacing: 10,
            children: genres.map<Widget>((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF714FDC).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  genre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF714FDC),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildTabsContainer(Map<String, dynamic> anime) {
    return Column(
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

        // Tab Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildTabContent(anime),
        ),
      ],
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
                      color: Colors.black.withOpacity(0.1),
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
        return _buildInformationTab(anime);
      case 1:
        return _buildCharactersTab(anime);
      case 2:
        return _buildRelationsTab(anime);
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
        ? "${anime['season']} ${anime['seasonYear'] ?? ''}"
        : "Unknown";
    final source = anime['source']?.replaceAll('_', ' ') ?? "Unknown";
    final duration = anime['duration'] != null
        ? "${anime['duration']} mins"
        : "Unknown";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Details Rows
          _buildDetailRow("Start Date", startDate),
          _buildDetailRow("End Date", endDate),
          _buildDetailRow("Season", season),
          _buildDetailRow("Source", source),
          _buildDetailRow("Duration", duration),

          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),

          // Studio & Trailer
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Studio",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      studioName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailer != null && trailer['site'] == 'youtube')
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(
                      'https://www.youtube.com/watch?v=${trailer['id']}',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text("Trailer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
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
    final characters = anime['characters']?['nodes'] as List?;
    if (characters == null || characters.isEmpty) {
      return const Center(child: Text("No characters found"));
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: characters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final char = characters[index];
          final name = char['name']?['full'] ?? "Unknown";
          final image = char['image']?['medium'];
          final id = char['id'];

          return GestureDetector(
            onTap: () {
              if (id != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterDetailScreen(
                      characterId: id,
                      placeholderName: name,
                      placeholderImage: image,
                    ),
                  ),
                );
              }
            },
            child: SizedBox(
              width: 90,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(45), // Circle
                    child: image != null
                        ? Image.network(
                            image,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRelationsTab(Map<String, dynamic> anime) {
    final relations = anime['relations']?['edges'] as List?;
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

    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: validRelations.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final edge = validRelations[index];
          final node = edge['node'];
          final relationType =
              edge['relationType']?.replaceAll('_', ' ') ?? 'RELATED';

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
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: image != null
                        ? Image.network(
                            image,
                            width: 70,
                            height: 95,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 70,
                            height: 95,
                            color: Colors.grey[300],
                          ),
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
    );
  }

  Widget buildRecommendations(Map<String, dynamic> anime) {
    final recommendations = anime['recommendations']?['nodes'] as List?;
    if (recommendations == null || recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final validRecs = recommendations
        .where((node) => node['mediaRecommendation'] != null)
        .toList();

    if (validRecs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recommendations",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: validRecs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final rec = validRecs[index]['mediaRecommendation'];
                final title =
                    rec['title']?['romaji'] ??
                    rec['title']?['english'] ??
                    'Unknown';
                final image =
                    rec['coverImage']?['large'] ?? rec['coverImage']?['medium'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimeDetailScreen(anime: rec),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: image != null
                              ? Image.network(
                                  image,
                                  width: 100,
                                  height: 130,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 100,
                                  height: 130,
                                  color: Colors.grey[300],
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
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
                  buildStatsCard(widget.anime),
                  buildGenres(widget.anime),
                  buildDescription(widget.anime),
                  const SizedBox(height: 10),
                  buildTabsContainer(widget.anime),
                  buildRecommendations(widget.anime),
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
