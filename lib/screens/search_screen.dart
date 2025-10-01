import 'package:flutter/material.dart';
import '../services/anilist_service.dart';
import 'anime_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List animeList = [];
  bool isLoading = false;
  final TextEditingController _controller = TextEditingController();

  // Search Anime
  void searchAnime() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      animeList = [];
    });

    final results = await AniListService.searchAnime(query);

    setState(() {
      animeList = results;
      isLoading = false;
    });
  }

  // Helper to build genre chips
  Widget buildGenres(List<dynamic> genres) {
    return Wrap(
      spacing: 6.0,
      runSpacing: 4.0,
      children: genres.map<Widget>((genre) {
        return Chip(label: Text(genre), backgroundColor: Colors.blue.shade100);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Anime')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Search input
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter anime name...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: searchAnime,
                ),
              ),
              onSubmitted: (_) => searchAnime(),
            ),
            const SizedBox(height: 12),
            // Loading indicator
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              // Search results list
              Expanded(
                child: ListView.builder(
                  itemCount: animeList.length,
                  itemBuilder: (context, index) {
                    final anime = animeList[index];

                    // Safely extract title
                    final title =
                        anime['title']?['romaji'] ??
                        anime['title']?['english'] ??
                        'Unknown';

                    // Safely extract episodes
                    final episodes = anime['episodes']?.toString() ?? 'N/A';

                    // Safely extract release year
                    final startDate =
                        anime['startDate'] != null &&
                            anime['startDate']['year'] != null
                        ? anime['startDate']['year'].toString()
                        : 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AnimeDetailScreen(anime: anime),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cover Image on the left (safe check)
                              anime['coverImage']?['medium'] != null
                                  ? Image.network(
                                      anime['coverImage']['medium'],
                                      width: 80,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : SizedBox(width: 80, height: 120),
                              const SizedBox(width: 12),
                              // Details on the right
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text('Episodes: $episodes'),
                                        const SizedBox(width: 16),
                                        Text('Year: $startDate'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
}
