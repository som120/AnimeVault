import 'package:flutter/material.dart';

class AnimeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> anime;

  const AnimeDetailScreen({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(anime['title']?['romaji'] ?? 'Anime Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            if (anime['coverImage'] != null)
              Center(
                child: Image.network(
                  anime['coverImage']['large'],
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 20),

            // English title
            Text(
              anime['title']?['english'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // Genres
            if (anime['genres'] != null)
              Wrap(
                spacing: 8,
                children: (anime['genres'] as List)
                    .map((genre) => Chip(label: Text(genre)))
                    .toList(),
              ),

            const SizedBox(height: 20),

            // Description
            Text(
              anime['description'] != null
                  ? anime['description'].replaceAll(
                      RegExp(r'<[^>]*>'),
                      '',
                    ) // remove HTML tags
                  : 'No description available.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
