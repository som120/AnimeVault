//import 'package:ainme_vault/main.dart';
//import 'package:ainme_vault/utils/transitions.dart';
import 'package:flutter/material.dart';
import '../services/anilist_service.dart';
import 'anime_detail_screen.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List animeList = [];
  bool isLoading = false;
  bool isFocused = false;
  bool _isScrolled = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String selectedFilter = "Top 100";

  List<String> searchHistory = [];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onFocusChange);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.unfocus();
      isFocused = false;
      setState(() {});
    });

    _init();
  }

  void _onFocusChange() {
    if (_searchFocus.hasFocus) {
      setState(() {
        isFocused = true;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final scrolled = _scrollController.offset > 20;
      if (scrolled != _isScrolled) {
        setState(() {
          _isScrolled = scrolled;
        });
      }
    }
  }

  Future<void> _init() async {
    await _loadSearchHistory(); // wait until history loads fully
    await _fetchAnimeByCategory("Top 100", AniListService.getTopAnime);
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      searchHistory = prefs.getStringList('search_history') ?? [];
      if (searchHistory.length > 10) {
        searchHistory = searchHistory.sublist(0, 10);
      }
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', searchHistory);
  }

  Future<void> _addToHistory(String query) async {
    if (query.isEmpty) return;
    setState(() {
      searchHistory.remove(query);
      searchHistory.insert(0, query);
      if (searchHistory.length > 10) {
        searchHistory.removeLast();
      }
    });
    await _saveSearchHistory();
  }

  Future<void> _removeFromHistory(String query) async {
    setState(() {
      searchHistory.remove(query);
    });
    await _saveSearchHistory();
  }

  Future<void> _clearHistory() async {
    setState(() {
      searchHistory.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }

  Future<void> _fetchAnimeByCategory(
    String filterName,
    Future<List> Function() apiCall,
  ) async {
    // Prevent unnecessary reloads
    if (selectedFilter == filterName &&
        !isLoading &&
        animeList.isNotEmpty &&
        filterName != "Search") {
      return;
    }

    setState(() {
      isLoading = true;

      // Only clear search bar on filter change
      if (filterName != "Search") {
        _controller.clear();
        FocusManager.instance.primaryFocus?.unfocus(); // Robust unfocus
        _searchFocus.unfocus();
        isFocused = false;
      }

      selectedFilter = filterName;
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
  // Called while typing (debounce) → DOES NOT close keyboard
  void _performSearch(String text) {
    if (text.isEmpty) return;

    _addToHistory(text);
    _fetchAnimeByCategory("Search", () => AniListService.searchAnime(text));
  }

  // Called when pressing the "search" button → closes keyboard
  void searchAnimeSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _addToHistory(text);
    _fetchAnimeByCategory("Search", () => AniListService.searchAnime(text));

    FocusManager.instance.primaryFocus?.unfocus(); // ONLY HERE
  }

  // ------------------ UI HELPER ------------------
  Widget buildFilterButton(String label, Future<List> Function() apiCall) {
    final bool active = selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          _searchFocus.unfocus();
          isFocused = false;
          setState(() {});
          _fetchAnimeByCategory(label, apiCall);
        },
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
      transform: _isScrolled && !isFocused
          ? Matrix4.diagonal3Values(0.95, 0.9, 1.0)
          : Matrix4.identity(),
      transformAlignment: Alignment.topCenter,
      padding: EdgeInsets.symmetric(
        horizontal: _isScrolled && !isFocused ? 12 : 18,
        vertical: _isScrolled && !isFocused ? 0 : 4,
      ),
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
          GestureDetector(
            onTap: () {
              if (isFocused) {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() {
                  isFocused = false;
                  _controller.clear();
                });
                if (selectedFilter == "Search") {
                  _fetchAnimeByCategory("Top 100", AniListService.getTopAnime);
                }
              }
            },
            child: Icon(
              isFocused ? Icons.arrow_back : Icons.search,
              size: 24,
              color: isFocused ? const Color(0xFF714FDC) : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              focusNode: _searchFocus,
              controller: _controller,
              onChanged: (value) {
                setState(() {}); // update clear icon

                if (_debounce?.isActive ?? false) _debounce!.cancel();

                _debounce = Timer(const Duration(milliseconds: 600), () {
                  if (!mounted) return;
                  if (value.trim().isNotEmpty) {
                    _performSearch(
                      value.trim(),
                    ); // ✔ alive search with keyboard open
                  }
                });
              },

              onSubmitted: (_) =>
                  searchAnimeSubmit(), // ✔ closes keyboard only on submit

              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: "Search anime...",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                border: InputBorder.none,
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

  Widget buildSearchHistory() {
    if (searchHistory.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Searches",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: _clearHistory,
                child: const Text(
                  "Clear All",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: searchHistory.length,
            itemBuilder: (context, index) {
              final query = searchHistory[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(query),
                trailing: GestureDetector(
                  onTap: () => _removeFromHistory(query),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.close, size: 20, color: Colors.grey),
                  ),
                ),
                onTap: () {
                  _controller.text = query;
                  FocusManager.instance.primaryFocus?.unfocus();
                  isFocused = false;
                  searchAnimeSubmit();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ------------------ BUILD ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ------------------ Search Bar ------------------
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
                      buildFilterButton(
                        "Popular",
                        AniListService.getPopularAnime,
                      ),
                      buildFilterButton(
                        "Upcoming",
                        AniListService.getUpcomingAnime,
                      ),
                      buildFilterButton(
                        "Airing",
                        AniListService.getAiringAnime,
                      ),
                      buildFilterButton("Movies", AniListService.getTopMovies),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ------------------ List View / History ------------------
              Expanded(
                child: isFocused && _controller.text.isEmpty
                    ? buildSearchHistory()
                    : isLoading
                    ? const AnimeListShimmer()
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        cacheExtent: 100,
                        itemCount: animeList.length,
                        itemBuilder: (context, index) {
                          final anime = animeList[index];
                          return TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 50 * (1 - value)),
                                child: Transform.scale(
                                  scale: 0.85 + (0.15 * value),
                                  child: Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: AnimeListCard(
                              anime: anime,
                              rank: selectedFilter == "Top 100"
                                  ? index + 1
                                  : null,
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                _searchFocus.unfocus();
                                isFocused = false;
                                setState(() {});
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AnimeDetailScreen(anime: anime),
                                  ),
                                );
                              },
                            ),
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
    _searchFocus.removeListener(_onFocusChange);
    _searchFocus.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}

// ------------------ EXTRACTED WIDGET ------------------
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
                FadeInImageWidget(imageUrl: imageUrl, width: 70, height: 95),
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

                      // Format + Year (Color Removed)
                      Container(
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
                            Icon(
                              Icons.circle,
                              size: 4,
                              color: Colors.grey.shade500,
                            ),
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
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Colors.amber,
                          ),
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
                              horizontal: 8,
                              vertical: 4,
                            ),
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
              child: rank! <= 3
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: Shimmer.fromColors(
                            baseColor: rank == 1
                                ? Colors.amber[600]!
                                : rank == 2
                                ? Colors.grey[500]!
                                : rank == 3
                                ? Colors.brown[400]!
                                : Colors.indigo,
                            highlightColor: rank == 1
                                ? Colors.amber[100]!
                                : rank == 2
                                ? Colors.grey[200]!
                                : rank == 3
                                ? Colors.brown[200]!
                                : Colors.indigo.shade100,
                            period: const Duration(milliseconds: 1500),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
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
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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

class AnimeListShimmer extends StatelessWidget {
  const AnimeListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 95,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(
                          3,
                          (_) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Container(
                              height: 14,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: FadeInImage(
          placeholder: MemoryImage(kTransparentImage),
          image: ResizeImage(
            NetworkImage(imageUrl),
            width: (width * 3).toInt(), // Optimize decoding size
          ),
          width: width,
          height: height,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 250),
          imageErrorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }
}
