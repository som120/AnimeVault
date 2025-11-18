import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference animeCollection = FirebaseFirestore.instance
        .collection('anime');

    return Scaffold(
      appBar: AppBar(title: const Text("AnimeVault 🎬")),
      body: StreamBuilder<QuerySnapshot>(
        stream: animeCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No anime found 😢"));
          }

          final animeList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              var anime = animeList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(anime['title']),
                  subtitle: Text(anime['genre']),
                  trailing: Text("⭐ ${anime['rating']}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
