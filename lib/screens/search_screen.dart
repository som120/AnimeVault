import 'package:ainme_vault/main.dart';
import 'package:ainme_vault/theme/app_theme.dart';
import 'package:ainme_vault/utils/transitions.dart';
import 'package:flutter/material.dart';
import '../services/anilist_service.dart';
import 'anime_detail_screen.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List animeList = [];
  bool isLoading = false;
  bool isFocused = false;
  Timer? _debounce;

  String selectedFilter = "Top 100";

  @override
  void initState() {
    super.initState();
    // Initial load
    _fetchAnimeByCategory("Top 100", AniListService.getTopAnime);
  }

  // ------------------ 1. FIX IS HERE ------------------
  Future<void> _fetchAnimeByCategory(
      String filterName, Future<List> Function() apiCall) async {
    
    // Logic Fix: Added '&& animeList.isNotEmpty'
    // This ensures that if the list is empty (like at first launch), 
    // it fetches data even if the tab name matches.
    if (selectedFilter == filterName && 
        !isLoading && 
        filterName != "Search" && 
        animeList.isNotEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
      selectedFilter = filterName;
      if (filterName != "Search") _controller.clear();
    });

    try {
      final data = await apiCall();
      if (!mounted) return;
      setState(() {
        animeList = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // ------------------ SEARCH FUNCTION ------------------
  void searchAnime() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _fetchAnimeByCategory("Search", () => AniListService.searchAnime(text));
  }

  // ------------------ UI HELPER ------------------
  Widget buildFilterButton(String label, Future<List> Function() apiCall) {
    final bool active = selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => _fetchAnimeByCategory(label, apiCall),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF714FDC) : Colors.grey[300],
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAnimatedSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(isFocused ? 30 : 24),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 24,
            color: isFocused ? const Color(0xFF714FDC) : Colors.grey[500],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FocusScope(
              child: Focus(
                onFocusChange: (hasFocus) => setState(() => isFocused = hasFocus),
                child: TextField(
                  controller: _controller,
                  onChanged: (value) {
                    setState(() {});
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 600), () {
                      if (!mounted) return;
                      if (value.trim().isNotEmpty) searchAnime();
                    });
                  },
                  onSubmitted: (_) => searchAnime(),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: "Search anime...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {});
                // Optional: If you want clearing search to go back to Top 100:
                // _fetchAnimeByCategory("Top 100", AniListService.getTopAnime);
              },
              child: const Icon(Icons.close, size: 20, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  // ------------------ BUILD ------------------
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
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF714FDC), Color(0xFF9F6DFF), AppTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          title: null,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              buildAnimatedSearchBar(),
              const SizedBox(height: 10),

              // ------------------ Filter Buttons ------------------
              SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildFilterButton("Top 100", AniListService.getTopAnime),
                      buildFilterButton("Popular", AniListService.getPopularAnime),
                      buildFilterButton("Upcoming", AniListService.getUpcomingAnime),
                      buildFilterButton("Airing", AniListService.getAiringAnime),
                      buildFilterButton("Movies", AniListService.getTopMovies),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ------------------ List View ------------------
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: animeList.length,
                        itemBuilder: (context, index) {
                          final anime = animeList[index];
                          return AnimeListCard(
                            anime: anime,
                            rank: selectedFilter == "Top 100" ? index + 1 : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AnimeDetailScreen(anime: anime),
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
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}

// ------------------ 2. EXTRACTED WIDGET (Removed Box Color) ------------------
class AnimeListCard extends StatelessWidget {
  final dynamic anime;
  final int? rank;
  final VoidCallback onTap;

  const AnimeListCard({
    super.key,
    required this.anime,
    this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        anime['coverImage']?['medium'] ?? anime['coverImage']?['large'];
    final title =
        anime['title']?['romaji'] ?? anime['title']?['english'] ?? 'Unknown';
    final score = anime['averageScore']?.toString() ?? 'N/A';
    final year = anime['startDate']?['year']?.toString() ?? '—';
    final episodes = anime['episodes']?.toString() ?? "N/A";

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    width: 70,
                    height: 95,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 70,
                      height: 95,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ⭐ Format + Year (Color Removed)
                      // I removed the decoration: BoxDecoration(...)
                      Container(
                        // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Optional: reduce padding if no box
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              anime['format'] ?? "TV",
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.circle,
                                size: 4, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              year,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            "$score%",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text("•", style: TextStyle(color: Colors.grey)),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF714FDC).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$episodes eps",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF714FDC).withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (rank != null)
            Positioned(
              top: 6,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rank == 1
                      ? Colors.amber[600]
                      : rank == 2
                          ? Colors.grey[500]
                          : rank == 3
                              ? Colors.brown[400]
                              : Colors.indigo,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "#$rank",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}