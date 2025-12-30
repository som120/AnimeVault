import 'dart:async';
import 'package:ainme_vault/screens/anime_detail_screen.dart';
import 'package:ainme_vault/services/anilist_service.dart';
import 'package:ainme_vault/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---------------- STATE VARIABLES ----------------
  final PageController _pageController = PageController();
  List<dynamic> _airingAnimeList = [];
  bool _isLoading = true;
  bool _isDark(Color c) => c.computeLuminance() < 0.5;
  String _selectedStatus = 'Completed';

  Timer? _timer;
  static const double _cardHorizontalMargin = 24.0;

  late final ValueNotifier<Color> _bgColorNotifier;
  late final ValueNotifier<int> _pageIndexNotifier;

  Color _processCoverColor(Color color) {
    final hsl = HSLColor.fromColor(color);

    // Clamp saturation (avoid neon colors)
    final double saturation = hsl.saturation.clamp(0.25, 0.55);

    // Clamp lightness (avoid too dark / too bright)
    final double lightness = hsl.lightness.clamp(0.55, 0.75);

    final softened = hsl
        .withSaturation(saturation)
        .withLightness(lightness)
        .toColor();

    // Blend slightly with white for UI softness
    return Color.lerp(softened, Colors.white, 0.15)!;
  }

  Color _getProcessedColor(int index) {
    if (index < 0 || index >= _airingAnimeList.length) {
      return Colors.white;
    }

    final hex = _airingAnimeList[index]['coverImage']?['color'];
    if (hex == null) return Colors.white;

    return _processCoverColor(_hexToColor(hex));
  }

  // ---------------- LIFECYCLE ----------------
  @override
  void initState() {
    super.initState();
    _bgColorNotifier = ValueNotifier(Colors.white);
    _pageIndexNotifier = ValueNotifier(0);
    _fetchAiringAnime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bgColorNotifier.dispose();
    _pageIndexNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ---------------- DATA FETCHING ----------------
  Future<void> _fetchAiringAnime() async {
    try {
      final data = await AniListService.getAiringAnime();
      if (mounted) {
        setState(() {
          // Take top 5
          _airingAnimeList = data.take(5).toList();
          _isLoading = false;

          // Set initial color if available
          if (_airingAnimeList.isNotEmpty) {
            _bgColorNotifier.value = _getProcessedColor(0);
            _pageIndexNotifier.value = 0;
            _startAutoScroll();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint("Error fetching airing anime: $e");
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) {
      hex = "FF$hex";
    }
    return Color(int.parse(hex, radix: 16));
  }

  void _startAutoScroll() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients || _airingAnimeList.isEmpty) return;

      final current = _pageIndexNotifier.value;
      final next = (current + 1) % _airingAnimeList.length;

      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  // ---------------- UI BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We extend body behind app bar if we want the color to go all the way up,
      // but standard approach is fine too.
      body: Stack(
        children: [
          // 1. Dynamic Background Layer
          // This fills the top part or whole screen based on design.
          // User said "behind the banner make the purple color white and make it dynamic"
          // We'll make a large curved background or simpler block.
          Positioned.fill(
            child: Column(
              children: [
                ValueListenableBuilder<Color>(
                  valueListenable: _bgColorNotifier,
                  builder: (_, color, __) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 360,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color,
                            Color.lerp(color, Colors.white, 0.35)!,
                            Colors.white,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    );
                  },
                ),
                Expanded(child: Container(color: Colors.white)),
              ],
            ),
          ),

          // 2. Content Layer
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Greeting
                ValueListenableBuilder<Color>(
                  valueListenable: _bgColorNotifier,
                  builder: (_, bgColor, __) {
                    final textColor = _isDark(bgColor)
                        ? Colors.white
                        : Colors.black87;

                    return RepaintBoundary(
                      child: GreetingSection(textColor: textColor),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Carousel
                if (_isLoading)
                  _buildLoadingShimmer()
                else if (_airingAnimeList.isEmpty)
                  const Center(child: Text("No airing anime found"))
                else
                  Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollStartNotification) {
                              _timer?.cancel();
                            } else if (notification is ScrollEndNotification) {
                              _startAutoScroll();
                            }
                            return false; // allow notification to bubble
                          },
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _airingAnimeList.length,
                            onPageChanged: (index) {
                              _pageIndexNotifier.value = index;
                              _bgColorNotifier.value = _getProcessedColor(
                                index,
                              );
                            },
                            itemBuilder: (context, index) {
                              final anime = _airingAnimeList[index];
                              return _buildAnimeCard(anime);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Indicators
                      ValueListenableBuilder<int>(
                        valueListenable: _pageIndexNotifier,
                        builder: (_, current, __) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_airingAnimeList.length, (
                              index,
                            ) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 8,
                                width: current == index ? 24 : 8,
                                decoration: BoxDecoration(
                                  color: current == index
                                      ? AppTheme.primary
                                      : AppTheme.accent.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My List",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.grid_view_rounded),
                            style: IconButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                            ),
                            onPressed: () {
                              // TODO: grid view toggle
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.filter_list_rounded),
                            style: IconButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                            ),
                            onPressed: () {
                              // TODO: open filter bottom sheet
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        _statusChip("Completed"),
                        const SizedBox(width: 12),
                        _statusChip("Planning"),
                        const SizedBox(width: 12),
                        _statusChip("Watching"),
                      ],
                    ),
                  ),
                ),

                Expanded(child: MyAnimeList(status: _selectedStatus)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label) {
    final bool isSelected = _selectedStatus == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimeCard(dynamic anime) {
    final coverImage = anime['coverImage']?['large'] ?? "";
    final title = anime['title']?['english'] ?? anime['title']?['romaji'] ?? "";
    final score = ((anime['averageScore'] ?? 0) as num) / 10;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailScreen(anime: anime),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: _cardHorizontalMargin),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: coverImage,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              // Gradient Overlay for Title readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        score.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        itemCount: 1,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: _cardHorizontalMargin,
            ),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MyAnimeList extends StatelessWidget {
  final String status;

  const MyAnimeList({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Login to track your anime",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('anime')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No $status anime found 😢",
              style: const TextStyle(color: Colors.black54),
            ),
          );
        }

        final animeList = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: animeList.length,
          itemBuilder: (context, index) {
            final doc = animeList[index];
            final data = doc.data() as Map<String, dynamic>;

            final title = data['title'] ?? 'Unknown';
            final rating = data['averageScore'] != null
                ? (data['averageScore'] / 10).toStringAsFixed(1)
                : '?';
            final progress = data['progress'] ?? 0;
            final totalEpisodes = data['totalEpisodes'] ?? '?';

            // Reconstruct anime object from Firestore data
            final anime = {
              'id': data['id'],
              'title': {'english': data['title'], 'romaji': data['title']},
              'coverImage': {'large': data['coverImage']},
              'averageScore': data['averageScore'],
              'episodes': data['totalEpisodes'],
            };

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnimeDetailScreen(anime: anime),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: data['coverImage'] != null
                      ? CachedNetworkImage(
                          imageUrl: data['coverImage'],
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : Container(width: 50, height: 70, color: Colors.grey),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text("Ep: $progress / $totalEpisodes"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$rating",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class GreetingSection extends StatelessWidget {
  final Color textColor;

  const GreetingSection({super.key, required this.textColor});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    // Get current user from Firebase
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "Anime Fan";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayName,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
