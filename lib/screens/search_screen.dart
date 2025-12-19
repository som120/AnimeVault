//import 'package:ainme_vault/main.dart';
//import 'package:ainme_vault/utils/transitions.dart';
import 'package:flutter/material.dart';
import '../services/anilist_service.dart';
import 'anime_detail_screen.dart';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  final String? initialGenre;
  const SearchScreen({super.key, this.initialGenre});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List animeList = [];
  bool isLoading = false;
  bool hasError = false;
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
    if (widget.initialGenre != null) {
      await _fetchAnimeByCategory(
        widget.initialGenre!,
        () => AniListService.getAnimeByGenre(widget.initialGenre!),
      );
    } else {
      await _fetchAnimeByCategory("Top 100", AniListService.getTopAnime);
    }
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
        filterName != "Search" &&
        !hasError) {
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false; // Reset error state on new fetch

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

      // For search, an empty list is a valid result (no results).
      // For categories (Top 100, Popular, etc), an empty list likely indicates a fetch error.
      if (data.isEmpty && filterName != "Search") {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        return;
      }

      setState(() {
        animeList = data;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
      });
      debugPrint("Search error: $e");
    }
  }

  // ------------------ SEARCH FUNCTION ------------------
  // Called while typing (debounce) → DOES NOT close keyboard
  Future<void> _performSearch(String text) async {
    if (text.isEmpty) return;

    await _addToHistory(text);
    await _fetchAnimeByCategory(
      "Search",
      () => AniListService.searchAnime(text),
    );
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

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Something went wrong",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "We couldn't load the anime list.\nPlease check your connection.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            _RetryButton(
              onPressed: () async {
                if (selectedFilter == "Search") {
                  await _performSearch(_controller.text);
                } else {
                  // Re-fetch current category
                  // Note: We need a way to call the original apiCall.
                  // Since we don't store the apiCall, we can just call the category fetch logic again.
                  if (selectedFilter == "Top 100") {
                    await _fetchAnimeByCategory(
                      "Top 100",
                      AniListService.getTopAnime,
                    );
                  } else if (selectedFilter == "Popular") {
                    await _fetchAnimeByCategory(
                      "Popular",
                      AniListService.getPopularAnime,
                    );
                  } else if (selectedFilter == "Upcoming") {
                    await _fetchAnimeByCategory(
                      "Upcoming",
                      AniListService.getUpcomingAnime,
                    );
                  } else if (selectedFilter == "Airing") {
                    await _fetchAnimeByCategory(
                      "Airing",
                      AniListService.getAiringAnime,
                    );
                  } else if (selectedFilter == "Movies") {
                    await _fetchAnimeByCategory(
                      "Movies",
                      AniListService.getTopMovies,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
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
                      // Show genre filter if active and not a standard filter
                      if (selectedFilter != "Top 100" &&
                          selectedFilter != "Popular" &&
                          selectedFilter != "Upcoming" &&
                          selectedFilter != "Airing" &&
                          selectedFilter != "Movies" &&
                          selectedFilter != "Calendar" &&
                          selectedFilter != "Search")
                        Padding(
                          padding: const EdgeInsets.only(left: 6, right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF714FDC),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selectedFilter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    _fetchAnimeByCategory(
                                      "Top 100",
                                      AniListService.getTopAnime,
                                    );
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      buildFilterButton("Top 100", AniListService.getTopAnime),
                      // Calendar Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            _searchFocus.unfocus();
                            isFocused = false;
                            setState(() {
                              selectedFilter = "Calendar";
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selectedFilter == "Calendar"
                                  ? const Color(0xFF714FDC)
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              "Calendar",
                              style: TextStyle(
                                color: selectedFilter == "Calendar"
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
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
                    : selectedFilter == "Calendar"
                    ? const _CalendarView()
                    : isLoading
                    ? const AnimeListShimmer()
                    : hasError
                    ? _buildErrorWidget()
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
                            period: const Duration(milliseconds: 1200),
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
          period: const Duration(milliseconds: 1200),
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
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          memCacheWidth: (width * 3).toInt(), // Optimize memory usage
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

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  int _selectedDayIndex = 0;
  late final List<DateTime> _days;
  final Map<int, List<dynamic>> _scheduleCache = {}; // Cache for each day

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _days = List.generate(7, (index) => now.add(Duration(days: index)));
  }

  String _getDayName(int weekday) {
    const days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    return days[weekday - 1];
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<List<dynamic>> _fetchSchedule() async {
    // Check if data is already cached
    if (_scheduleCache.containsKey(_selectedDayIndex)) {
      return _scheduleCache[_selectedDayIndex]!;
    }

    // Fetch new data
    final date = _days[_selectedDayIndex];
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    final start = startOfDay.millisecondsSinceEpoch ~/ 1000;
    final end = endOfDay.millisecondsSinceEpoch ~/ 1000;

    final schedules = await AniListService.getAiringSchedule(
      start: start,
      end: end,
      perPage: 50,
    );

    // Cache the result
    _scheduleCache[_selectedDayIndex] = schedules;

    return schedules;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Day Tabs
        Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final date = _days[index];
              final isSelected = index == _selectedDayIndex;

              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getDayName(date.weekday),
                      style: TextStyle(
                        color: isSelected ? Colors.black87 : Colors.grey,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: 3,
                      width: isSelected ? 24 : 0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF714FDC),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Grid Content
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            key: ValueKey(_selectedDayIndex),
            future: _fetchSchedule(),
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final schedules = snapshot.data ?? [];
              final itemCount = isLoading ? 12 : schedules.length;

              if (!isLoading && schedules.isEmpty) {
                return const Center(
                  child: Text("No anime airing on this day."),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 20,
                ),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  // Staggered animation delay based on index
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (index * 50)),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: isLoading
                        ? _buildSkeletonCard()
                        : _buildAnimeCard(schedules[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 14,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 12,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimeCard(dynamic item) {
    final media = item['media'];
    final airingAt = item['airingAt'];
    final episode = item['episode'];

    if (media == null) return const SizedBox.shrink();

    final title =
        media['title']?['romaji'] ?? media['title']?['english'] ?? "Unknown";
    final image =
        media['coverImage']?['large'] ?? media['coverImage']?['medium'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailScreen(anime: media),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: image != null
                  ? CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                  : Container(color: Colors.grey[200]),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Ep $episode at ${_formatTime(airingAt)}",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  const _RetryButton({required this.onPressed});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      onTap: _isLoading
          ? null
          : () async {
              setState(() {
                _isLoading = true;
              });
              _controller.repeat();

              // Run minimum delay and task in parallel
              // This ensures we see the animation for at least 1s
              // but also wait for the actual network request if it takes longer.
              final minDelay = Future.delayed(
                const Duration(milliseconds: 1000),
              );
              final task = widget.onPressed();

              await Future.wait([minDelay, task]);

              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _controller.stop();
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF714FDC),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF714FDC).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isLoading
            ? RotationTransition(
                turns: _controller,
                child: const Icon(Icons.refresh, color: Colors.white, size: 20),
              )
            : const Text(
                "Retry",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
