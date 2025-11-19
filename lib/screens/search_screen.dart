import 'package:ainme_vault/theme/app_theme.dart';
import 'package:flutter/material.dart';
import '../services/anilist_service.dart';
import 'anime_detail_screen.dart';

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

  String selectedFilter = "Top 100";

  @override
  void initState() {
    super.initState();
    fetchTopAnime(); // default
  }

  // ------------------ CATEGORY FUNCTIONS ------------------

  void fetchTopAnime() async {
    setState(() {
      isLoading = true;
      selectedFilter = "Top 100";
    });
    animeList = await AniListService.getTopAnime();
    setState(() => isLoading = false);
  }

  void fetchPopular() async {
    setState(() {
      isLoading = true;
      selectedFilter = "Popular";
    });
    animeList = await AniListService.getPopularAnime();
    setState(() => isLoading = false);
  }

  void fetchUpcoming() async {
    setState(() {
      isLoading = true;
      selectedFilter = "Upcoming";
    });
    animeList = await AniListService.getUpcomingAnime();
    setState(() => isLoading = false);
  }

  void fetchAiring() async {
    setState(() {
      isLoading = true;
      selectedFilter = "Airing";
    });
    animeList = await AniListService.getAiringAnime();
    setState(() => isLoading = false);
  }

  void fetchMovies() async {
    setState(() {
      isLoading = true;
      selectedFilter = "Movies";
    });
    animeList = await AniListService.getTopMovies();
    setState(() => isLoading = false);
  }

  // ------------------ SEARCH FUNCTION ------------------
  void searchAnime() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      isLoading = true;
      selectedFilter = "Search";
    });

    animeList = await AniListService.searchAnime(text);
    setState(() => isLoading = false);
  }

  // ------------------ UI BUTTON WIDGET ------------------

  Widget buildFilterButton(String label, Function onTap) {
    final bool active = selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () => onTap(),
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

  Widget buildAnimeCard(anime, int? rank) {
    final imageUrl =
        anime['coverImage']?['medium'] ?? anime['coverImage']?['large'];

    final title =
        anime['title']?['romaji'] ?? anime['title']?['english'] ?? 'Unknown';

    final score = anime['averageScore']?.toString() ?? 'N/A';
    final year = anime['startDate']?['year']?.toString() ?? '—';
    final episodes = anime['episodes']?.toString() ?? "N/A";

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // MAIN CARD
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
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // FORMAT + YEAR
                    Row(
                      children: [
                        Text(
                          anime['format'] ?? "TV",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text("•", style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 6),
                        Text(
                          year,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // ⭐ SCORE + EPISODES
                    Row(
                      children: [
                        // ⭐ SCORE
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

                        // SEPARATOR DOT
                        const Text("•", style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 12),

                        // EPISODES TAG
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

        // ⭐ RANK BADGE (only visible if rank != null)
        if (rank != null)
          Positioned(
            top: 6,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: rank == 1
                    ? Colors.amber[600] // Gold
                    : rank == 2
                    ? Colors.grey[500] // Silver
                    : rank == 3
                    ? Colors.brown[400] // Bronze
                    : Colors.indigo, // Others
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
          // 🔍 Icon
          Icon(
            Icons.search,
            size: 24,
            color: isFocused ? const Color(0xFF714FDC) : Colors.grey[500],
          ),

          const SizedBox(width: 12),

          // ✏ Text Input
          Expanded(
            child: FocusScope(
              child: Focus(
                onFocusChange: (hasFocus) {
                  setState(() => isFocused = hasFocus);
                },
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => searchAnime(),
                  decoration: const InputDecoration(
                    hintText: "Search anime...",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),

          // ❌ Clear button
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {});
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
    return Scaffold(
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
            // ------------------------Search bar----------------------
            buildAnimatedSearchBar(),
            const SizedBox(height: 10),

            // ------------------ Filter Buttons Row ------------------
            SizedBox(
              height: 40,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    buildFilterButton("Top 100", fetchTopAnime),
                    buildFilterButton("Popular", fetchPopular),
                    buildFilterButton("Upcoming", fetchUpcoming),
                    buildFilterButton("Airing", fetchAiring),
                    buildFilterButton("Movies", fetchMovies),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ------------------ Anime List ------------------
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: animeList.length,
                      itemBuilder: (context, index) {
                        final anime = animeList[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AnimeDetailScreen(anime: anime),
                              ),
                            );
                          },
                          child: buildAnimeCard(
                            anime,
                            selectedFilter == "Top 100" ? index + 1 : null,
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
}
