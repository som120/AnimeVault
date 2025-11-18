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

  // ---------------- SEARCH ----------------
  static const String searchQuery = r'''
    query ($search: String) {
      Page(perPage: 20) {
        media(search: $search, type: ANIME) {
          id
          title {
            romaji
            english
          }
          episodes
          averageScore
          startDate { year }
          coverImage {
            large
            medium
          }
        }
      }
    }
  ''';

  // ---------------- TOP 100 ----------------
  static const String topAnimeQuery = r'''
    query {
      Page(perPage: 20) {
        media(type: ANIME, sort: SCORE_DESC) {
          id
          title {
            romaji
            english
          }
          episodes
          averageScore
          startDate { year }
          coverImage { large medium }
        }
      }
    }
  ''';

  // ---------------- POPULAR ----------------
  static const String popularAnimeQuery = r'''
    query {
      Page(perPage: 20) {
        media(type: ANIME, sort: POPULARITY_DESC) {
          id
          title {
            romaji
            english
          }
          episodes
          averageScore
          startDate { year }
          coverImage { large medium }
        }
      }
    }
  ''';

  // ---------------- UPCOMING ----------------
  static const String upcomingAnimeQuery = r'''
    query {
      Page(perPage: 20) {
        media(type: ANIME, status: NOT_YET_RELEASED, sort: START_DATE) {
          id
          title {
            romaji
            english
          }
          episodes
          averageScore
          startDate { year }
          coverImage { large medium }
        }
      }
    }
  ''';

  // ---------------- AIRING ----------------
  static const String airingAnimeQuery = r'''
    query {
      Page(perPage: 20) {
        media(type: ANIME, status: RELEASING, sort: TRENDING_DESC) {
          id
          title {
            romaji
            english
          }
          episodes
          averageScore
          startDate { year }
          coverImage { large medium }
        }
      }
    }
  ''';

  // ---------------- TOP MOVIES ----------------
  static const String topMoviesQuery = r'''
    query {
      Page(perPage: 20) {
        media(type: ANIME, format: MOVIE, sort: SCORE_DESC) {
          id
          title {
            romaji
            english
          }
          episodes
          averageScore
          startDate { year }
          coverImage { large medium }
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
    );

    final result = await client().query(options);

    if (result.hasException) {
      debugPrint("🔥 AniList Error: ${result.exception}");
      return [];
    }

    return result.data?['Page']?['media'] ?? [];
  }

  // ------------ PUBLIC FUNCTIONS ------------

  static Future<List> searchAnime(String name) async =>
      _fetch(searchQuery, variables: {"search": name});

  static Future<List> getTopAnime() async => _fetch(topAnimeQuery);

  static Future<List> getPopularAnime() async => _fetch(popularAnimeQuery);

  static Future<List> getUpcomingAnime() async => _fetch(upcomingAnimeQuery);

  static Future<List> getAiringAnime() async => _fetch(airingAnimeQuery);

  static Future<List> getTopMovies() async => _fetch(topMoviesQuery);
}
