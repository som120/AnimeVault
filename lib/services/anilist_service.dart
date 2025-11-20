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
    query ($search: String) {
      Page(perPage: 20) {
        media(search: $search, type: ANIME) {
          id
          title { romaji english }
          format
          description(asHtml: false)
          episodes
          averageScore
          status
          bannerImage
          startDate { year }
          coverImage { large medium }
        }
      }
    }
  ''';

  static const String topAnimeQuery = r'''
    query {
      Page(perPage: 100) {
        media(sort: SCORE_DESC, type: ANIME) {
          id
          title { romaji english }
          format
          description(asHtml: false)
          episodes
          averageScore
          status
          bannerImage
          startDate { year }
          coverImage { medium large }
        }
      }
    }
  ''';

  static const String popularAnimeQuery = r'''
    query {
      Page(perPage: 100) {
        media(sort: POPULARITY_DESC, type: ANIME) {
          id
          title { romaji english }
          format
          description(asHtml: false)
          episodes
          averageScore
          status
          bannerImage
          startDate { year }
          coverImage { medium large }
        }
      }
    }
  ''';

  static const String upcomingAnimeQuery = r'''
    query {
      Page(perPage: 100) {
        media(sort: POPULARITY_DESC, type: ANIME, status: NOT_YET_RELEASED) {
          id
          title { romaji english }
          format
          description(asHtml: false)
          episodes
          averageScore
          status
          bannerImage
          startDate { year }
          coverImage { medium large }
        }
      }
    }
  ''';

  static const String airingAnimeQuery = r'''
    query {
      Page(perPage: 100) {
        media(sort: TRENDING_DESC, type: ANIME, status: RELEASING) {
          id
          title { romaji english }
          format
          description(asHtml: false)
          episodes
          averageScore
          status
          bannerImage
          startDate { year }
          coverImage { medium large }
        }
      }
    }
  ''';

  static const String topMoviesQuery = r'''
    query {
      Page(perPage: 100) {
        media(sort: SCORE_DESC, type: ANIME, format: MOVIE) {
          id
          title { romaji english }
          format
          description(asHtml: false)
          episodes
          averageScore
          status
          bannerImage
          startDate { year }
          coverImage { medium large }
        }
      }
    }
  ''';

  // ------------ GENERIC FETCH FUNCTION ------------
  static Future<List> _fetch(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final options = QueryOptions(
      document: gql(query),
      variables: variables ?? {},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await client().query(options);

    if (result.hasException) {
      debugPrint('AniList API Error: ${result.exception}');
      return [];
    }

    // safe access with null checks
    final page = result.data?['Page'];
    if (page == null) return [];
    final media = page['media'];
    if (media == null) return [];
    return List.from(media);
  }

  // ------------ PUBLIC FUNCTIONS ------------
  static Future<List> searchAnime(String name) async =>
      _fetch(searchQuery, variables: {'search': name});

  static Future<List> getTopAnime() async => _fetch(topAnimeQuery);

  static Future<List> getPopularAnime() async => _fetch(popularAnimeQuery);

  static Future<List> getUpcomingAnime() async => _fetch(upcomingAnimeQuery);

  static Future<List> getAiringAnime() async => _fetch(airingAnimeQuery);

  static Future<List> getTopMovies() async => _fetch(topMoviesQuery);
}
