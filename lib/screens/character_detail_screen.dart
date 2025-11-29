import 'package:ainme_vault/services/anilist_service.dart';
import 'package:ainme_vault/theme/app_theme.dart';
import 'package:ainme_vault/screens/anime_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

class CharacterDetailScreen extends StatefulWidget {
  final int characterId;
  final String? placeholderName;
  final String? placeholderImage;

  const CharacterDetailScreen({
    super.key,
    required this.characterId,
    this.placeholderName,
    this.placeholderImage,
    this.scrollController,
  });

  final ScrollController? scrollController;

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
        controller: widget.scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
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
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null)
                    FadeInImage(
                      placeholder: MemoryImage(kTransparentImage),
                      image: ResizeImage(
                        NetworkImage(image),
                        width: 800, // High res for header
                      ),
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 300),
                    )
                  else
                    Container(color: Colors.grey),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.6, 1.0],
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
                    Center(
                      child: Text(
                        nativeName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],

                  // Info Grid
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                              "Age",
                              age,
                              Icons.cake_rounded,
                              Colors.pinkAccent,
                            ),
                            _buildInfoItem(
                              "Gender",
                              gender,
                              Icons.person_rounded,
                              Colors.blueAccent,
                            ),
                            _buildInfoItem(
                              "Blood",
                              bloodType,
                              Icons.bloodtype_rounded,
                              Colors.redAccent,
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Divider(indent: 20, endIndent: 20),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                              "Birthday",
                              birthday,
                              Icons.calendar_today_rounded,
                              Colors.orangeAccent,
                            ),
                            _buildInfoItem(
                              "Favourites",
                              favourites,
                              Icons.favorite_rounded,
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Description
                  const Text(
                    "About",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  AnimatedCrossFade(
                    firstChild: Text(
                      description,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                    secondChild: Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.6,
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
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isDescriptionExpanded ? "Read Less" : "Read More",
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Icon(
                            isDescriptionExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppTheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Appearances
                  if (character?['media']?['nodes'] != null &&
                      (character!['media']['nodes'] as List).isNotEmpty) ...[
                    const Text(
                      "Appearances",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 200, // Increased height
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            (character!['media']['nodes'] as List).length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 15),
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
                              width: 120, // Increased width
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  image != null
                                      ? FadeInImageWidget(
                                          imageUrl: image,
                                          width: 120,
                                          height: 160,
                                        )
                                      : Container(
                                          width: 120,
                                          height: 160,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
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

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(12),
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
