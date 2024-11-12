import 'package:flutter/material.dart';

class FavoriteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Anime List'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Favorites'),
              Tab(text: 'Watching'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AnimeListTab(animeStatus: 'favorite'), // List for favorites
            AnimeListTab(animeStatus: 'watching'), // List for currently watching
            AnimeListTab(animeStatus: 'completed'), // List for completed
          ],
        ),
      ),
    );
  }
}

class AnimeListTab extends StatelessWidget {
  final String animeStatus;

  const AnimeListTab({required this.animeStatus});

  @override
  Widget build(BuildContext context) {
    // Replace this with real data fetching and filtering based on animeStatus
    return Center(child: Text('List of $animeStatus animes'));
  }
}
