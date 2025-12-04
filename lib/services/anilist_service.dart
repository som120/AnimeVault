import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class AniListService {
  static final HttpLink httpLink = HttpLink('https://graphql.anilist.co');

  static GraphQLClient client() {
    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  // ---------------- QUERY CONSTANTS ----------------
  static const String searchQuery = r'''
     query ($search: String, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        media(search: $search, type: ANIME) {
          id
          title { romaji english }
          format
          genres
          description(asHtml: false)
          episodes
          averageScore
          popularity
          favourites
          rankings { rank type allTime }
          status
          bannerImage
          startDate { year }
          coverImage { large medium }
        }
      }
    }
  ''';

  static const String topAnimeQuery = r'''
    query ($page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        media(sort: SCORE_DESC, type: ANIME) {
          id
          title { romaji english }
          format
          genres
          description(asHtml: false)
          episodes
          averageScore
          popularity
          favourites
          rankings { rank type allTime }
          status
          bannerImage
          startDate { year }
          coverImage { medium large }
        }
      }
    }
  ''';

  static const String popularAnimeQuery = r'''
    query ($page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        media(sort: POPULARITY_DESC, type: ANIME) {
          id
          title { romaji english }
          format
          genres
          description(asHtml: false)
          episodes
          averageScore
          popularity
          favourites
          rankings { rank type allTime }
          status
          bannerImage
          startDate { year }
          coverImage { medium large }
        }
      }
    }
  ''';

  static const String upcomingAnimeQuery = r'''
    query ($page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        media(sort: POPULARITY_DESC, type: ANIME, status: NOT_YET_RELEASED) {
          id
          title { romaji english }
          format
          genres
          description(asHtml: false)
          episodes
          averageScore
          popularity
          favourites
          rankings { rank type allTime }
          status
          bannerImage
          startDate { year }
          coverImage { medium large }
        }
      }
    }
  ''';

  static const String airingAnimeQuery = r'''
    query ($page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        media(sort: TRENDING_DESC, type: ANIME, status: RELEASING) {
          id
          title { romaji english }
          format
          genres
          description(asHtml: false)
          episodes
          averageScore
          popularity
          favourites
          rankings { rank type allTime }
          status
          bannerImage
          startDate { year }
          coverImage { medium large }
        }
      }
    }
  ''';

  static const String topMoviesQuery = r'''
    query ($page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        media(sort: SCORE_DESC, type: ANIME, format: MOVIE) {
          id
          title { romaji english }
          format
          genres
          description(asHtml: false)
          episodes
          averageScore
          popularity
          favourites
          rankings { rank type allTime }
          status
          bannerImage
          startDate { year }
          coverImage { medium large }
        }
      }
    }
  ''';

  static const String genreQuery = r'''
    query ($genre: String, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        media(genre: $genre, sort: POPULARITY_DESC, type: ANIME) {
          id
          title { romaji english }
          format
          genres
          description(asHtml: false)
          episodes
          averageScore
          popularity
          favourites
          rankings { rank type allTime }
          status
          bannerImage
          startDate { year }
          coverImage { medium large }
        }
      }
    }
  ''';

  static const String mediaDetailQuery = r'''
    query ($id: Int) {
      Media(id: $id) {
        id
        title { romaji english }
        format
        genres
        description(asHtml: false)
        episodes
        averageScore
        popularity
        favourites
        rankings { rank type allTime }
        status
        bannerImage
        startDate { year month day }
        endDate { year month day }
        season
        seasonYear
        source
        duration
        coverImage { medium large }
        studios(isMain: true) { nodes { name } }
        trailer { id site thumbnail }
        characters(sort: [ROLE, RELEVANCE], perPage: 25) {
          edges {
            role
            node {
              id
              name { full }
              image { medium }
            }
          }
        }
        recommendations(sort: RATING_DESC, perPage: 25) {
          nodes {
            mediaRecommendation {
              id
              title { romaji english }
              format
              status
              coverImage { medium large }
            }
          }
        }
        relations {
          edges {
            relationType
            node {
              id
              title { romaji english }
              format
              status
              coverImage { medium large }
            }
          }
        }
        externalLinks {
          id
          url
          site
          type
          icon
          color
        }
      }
    }
  ''';

  static const String characterQuery = r'''
    query ($id: Int) {
      Character(id: $id) {
        id
        name { full native alternative }
        image { large }
        description(asHtml: false)
        gender
        dateOfBirth { year month day }
        age
        bloodType
        siteUrl
        favourites
        media(sort: POPULARITY_DESC, type: ANIME, perPage: 10) {
          nodes {
            id
            title { romaji }
            coverImage { medium }
          }
        }
      }
    }
  ''';

  // ------------ GENERIC FETCH FUNCTION ------------
  static Future<List<dynamic>> _fetch(
    String query, {
    Map<String, dynamic>? variables,
    FetchPolicy fetchPolicy = FetchPolicy.networkOnly,
  }) async {
    final opts = QueryOptions(
      document: gql(query),
      variables: variables ?? {},
      fetchPolicy: fetchPolicy,
    );

    try {
      final result = await client().query(opts);

      if (result.hasException) {
        debugPrint('AniList API Error: ${result.exception}');
        return [];
      }

      final page = result.data?['Page'];
      if (page == null) return [];
      final media = page['media'];
      if (media == null) return [];
      return List<dynamic>.from(media);
    } catch (e, st) {
      debugPrint('AniList fetch failed: $e\n$st');
      return [];
    }
  }

  // ------------ MULTI-PAGE FETCH (merge pages) ------------

  static Future<List<dynamic>> _fetchMultiplePages(
    String query, {
    int perPage = 50,
    int pages = 2,
    Map<String, dynamic>? otherVariables,
  }) async {
    final List<dynamic> combined = [];
    for (var p = 1; p <= pages; p++) {
      final vars = <String, dynamic>{'page': p, 'perPage': perPage};
      if (otherVariables != null) vars.addAll(otherVariables);
      final pageResult = await _fetch(
        query,
        variables: vars,
        fetchPolicy: FetchPolicy.networkOnly,
      );
      if (pageResult.isEmpty) {
        // If a page returns empty, break early
        break;
      }
      combined.addAll(pageResult);
    }
    return combined;
  }

  // ------------ PUBLIC FUNCTIONS ------------
  static Future<List<dynamic>> searchAnime(
    String name, {
    int page = 1,
    int perPage = 50,
  }) async => _fetch(
    searchQuery,
    variables: {'search': name, 'page': page, 'perPage': perPage},
  );

  static Future<List<dynamic>> getTopAnime() async =>
      _fetchMultiplePages(topAnimeQuery, perPage: 50, pages: 2);

  static Future<List<dynamic>> getPopularAnime() async =>
      _fetchMultiplePages(popularAnimeQuery, perPage: 50, pages: 2);

  static Future<List<dynamic>> getUpcomingAnime() async =>
      _fetchMultiplePages(upcomingAnimeQuery, perPage: 50, pages: 2);

  static Future<List<dynamic>> getAiringAnime() async =>
      _fetchMultiplePages(airingAnimeQuery, perPage: 50, pages: 2);

  static Future<List<dynamic>> getTopMovies() async =>
      _fetchMultiplePages(topMoviesQuery, perPage: 50, pages: 2);

  static Future<List<dynamic>> getAnimeByGenre(String genre) async =>
      _fetchMultiplePages(
        genreQuery,
        perPage: 50,
        pages: 2,
        otherVariables: {'genre': genre.trim()},
      );

  static Future<Map<String, dynamic>?> getCharacterDetails(int id) async {
    final opts = QueryOptions(
      document: gql(characterQuery),
      variables: {'id': id},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    try {
      final result = await client().query(opts);

      if (result.hasException) {
        debugPrint('AniList API Error: ${result.exception}');
        return null;
      }

      return result.data?['Character'];
    } catch (e, st) {
      debugPrint('AniList fetch failed: $e\n$st');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getAnimeDetails(int id) async {
    final opts = QueryOptions(
      document: gql(mediaDetailQuery),
      variables: {'id': id},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    try {
      final result = await client().query(opts);

      if (result.hasException) {
        debugPrint('AniList API Error: ${result.exception}');
        return null;
      }

      return result.data?['Media'];
    } catch (e, st) {
      debugPrint('AniList fetch failed: $e\n$st');
      return null;
    }
  }
}
