import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class AniListService {
  // GraphQL HTTP link
  static final HttpLink httpLink = HttpLink('https://graphql.anilist.co');

  // GraphQL client
  static GraphQLClient client() {
    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  }

  // Search query
  static const String searchQuery = r'''
    query ($search: String) {
      Page(perPage: 10) {
        media(search: $search, type: ANIME) {
          id
          title {
            romaji
            english
          }
          episodes
          coverImage {
            large
            medium
          }
          startDate {
          year
        }
          description
          genres
        }
      }
    }
  ''';

  // Function to search anime
  static Future<List> searchAnime(String query) async {
    final options = QueryOptions(
      document: gql(searchQuery),
      variables: {'search': query},
    );

    final result = await client().query(options);

    if (result.hasException) {
      debugPrint('AniList API Error: ${result.exception.toString()}');
      return [];
    }

    return result.data?['Page']['media'] ?? [];
  }
}
