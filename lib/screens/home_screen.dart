import 'dart:async';
import 'package:ainme_vault/screens/anime_detail_screen.dart';
import 'package:ainme_vault/services/anilist_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---------------- STATE VARIABLES ----------------
  final PageController _pageController = PageController(viewportFraction: 1.0);
  int _currentIndex = 0;
  List<dynamic> _airingAnimeList = [];
  bool _isLoading = true;

  Color _backgroundColor = Colors.white;
  Timer? _timer;

  // ---------------- LIFECYCLE ----------------
  @override
  void initState() {
    super.initState();
    _fetchAiringAnime();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
            _updateColor(0);
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

  void _updateColor(int index) {
    if (index >= 0 && index < _airingAnimeList.length) {
      final anime = _airingAnimeList[index];
      final colorHex = anime['coverImage']?['color'];
      if (colorHex != null) {
        setState(() {
          _backgroundColor = _hexToColor(colorHex);
        });
      } else {
        setState(() {
          _backgroundColor = Colors.white; // Default fallback
        });
      }
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
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentIndex + 1;
        if (nextPage >= _airingAnimeList.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 400, // Cover top portion
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _backgroundColor,
                        _backgroundColor.withOpacity(0.8),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Good Morning",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Anime Fan", // Placeholder for User Name
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _airingAnimeList.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                            _updateColor(index);
                          },
                          itemBuilder: (context, index) {
                            final anime = _airingAnimeList[index];
                            return _buildAnimeCard(anime);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_airingAnimeList.length, (
                          index,
                        ) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentIndex == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? Colors
                                        .white // Active dot matches bg or white?
                                  // Actually, on a potentially white background, white dots are invisible.
                                  // If the background is colored, white is fine.
                                  // But "behind the banner" is colored.
                                  // The dots are usually below the banner.
                                  // If the colored bg extends lower, white is good.
                                  // If not, we need a contrasting color.
                                  // Let's use a semi-transparent white/grey.
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('anime')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No tracked anime found 😢",
                            style: TextStyle(color: Colors.black54),
                          ),
                        );
                      }
                      final animeList = snapshot.data!.docs;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: animeList.length,
                        itemBuilder: (context, index) {
                          var anime = animeList[index];
                          // Handle potential missing fields gracefully
                          final title =
                              anime.data().toString().contains('title')
                              ? anime['title']
                              : 'Unknown';
                          final genre =
                              anime.data().toString().contains('genre')
                              ? anime['genre']
                              : 'Unknown';
                          final rating =
                              anime.data().toString().contains('rating')
                              ? anime['rating']
                              : '?';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(genre),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "⭐ $rating",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(dynamic anime) {
    final coverImage = anime['coverImage']?['large'] ?? "";
    final title = anime['title']?['english'] ?? anime['title']?['romaji'] ?? "";

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
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
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
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
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
                    color: Colors.black.withOpacity(0.7),
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
                        "${(anime['averageScore'] ?? 0) ~/ 10}.${(anime['averageScore'] ?? 0) % 10}",
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
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: 1,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
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
