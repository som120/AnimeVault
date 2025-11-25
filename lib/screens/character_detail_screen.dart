import 'package:ainme_vault/services/anilist_service.dart';
import 'package:ainme_vault/theme/app_theme.dart';
import 'package:ainme_vault/screens/anime_detail_screen.dart';
import 'package:flutter/material.dart';

class CharacterDetailScreen extends StatefulWidget {
  final int characterId;
  final String? placeholderName;
  final String? placeholderImage;

  const CharacterDetailScreen({
    super.key,
    required this.characterId,
    this.placeholderName,
    this.placeholderImage,
  });

  @override
  State<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen> {
  bool isLoading = true;
  Map<String, dynamic>? character;
  bool isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final data = await AniListService.getCharacterDetails(widget.characterId);
    if (mounted) {
      setState(() {
        character = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        character?['name']?['full'] ?? widget.placeholderName ?? "Unknown";
    final nativeName = character?['name']?['native'];
    final image = character?['image']?['large'] ?? widget.placeholderImage;
    final description =
        character?['description']?.replaceAll(RegExp(r'<[^>]*>'), '') ??
        "No description available.";
    final age = character?['age'] ?? "Unknown";
    final gender = character?['gender'] ?? "Unknown";
    final bloodType = character?['bloodType'] ?? "Unknown";
    final favourites = character?['favourites']?.toString() ?? "0";
    final dateOfBirth = character?['dateOfBirth'];
    String birthday = "Unknown";
    if (dateOfBirth != null &&
        dateOfBirth['month'] != null &&
        dateOfBirth['day'] != null) {
      birthday = "${dateOfBirth['month']}/${dateOfBirth['day']}";
      if (dateOfBirth['year'] != null) {
        birthday += "/${dateOfBirth['year']}";
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    Image.network(image, fit: BoxFit.cover)
                  else
                    Container(color: Colors.grey),
                  Container(
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
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (nativeName != null) ...[
                    Text(
                      nativeName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Info Grid
                  Container(
                    padding: const EdgeInsets.all(16),
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem("Age", age),
                            _buildInfoItem("Gender", gender),
                            _buildInfoItem("Blood", bloodType),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem("Birthday", birthday),
                            _buildInfoItem("Favourites", favourites),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    "About",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  AnimatedCrossFade(
                    firstChild: Text(
                      description,
                      maxLines: 6,
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isDescriptionExpanded = !isDescriptionExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        isDescriptionExpanded ? "Read Less" : "Read More",
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Appearances
                  if (character?['media']?['nodes'] != null &&
                      (character!['media']['nodes'] as List).isNotEmpty) ...[
                    const Text(
                      "Appearances",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            (character!['media']['nodes'] as List).length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final anime = character!['media']['nodes'][index];
                          final title = anime['title']?['romaji'] ?? "Unknown";
                          final image = anime['coverImage']?['medium'];

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
                            child: SizedBox(
                              width: 110,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: image != null
                                        ? Image.network(
                                            image,
                                            width: 110,
                                            height: 140,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 110,
                                            height: 140,
                                            color: Colors.grey[300],
                                          ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    title,
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
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
