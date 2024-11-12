// main_app_shell.dart
import 'package:animeverse/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'favorite.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainAppShell extends ConsumerWidget {
  const MainAppShell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      body: Row(
        children: [
          if (isTablet) _buildNavigationRail(context, selectedIndex, ref),
          Expanded(
            child: _buildScreen(selectedIndex),
          ),
        ],
      ),
      bottomNavigationBar: isTablet ? null : _buildBottomNav(context, selectedIndex, ref),
    );
  }

  Widget _buildNavigationRail(BuildContext context, int selectedIndex, WidgetRef ref) {
    return NavigationRail(
      extended: MediaQuery.of(context).size.width >= 1200,
      backgroundColor: Theme.of(context).primaryColor,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        ref.read(navigationIndexProvider.notifier).state = index;
      },
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.new_releases_outlined),
          selectedIcon: Icon(Icons.new_releases),
          label: Text('Recent'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: Text('My List'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, int selectedIndex, WidgetRef ref) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        ref.read(navigationIndexProvider.notifier).state = index;
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.new_releases_outlined),
          selectedIcon: Icon(Icons.new_releases),
          label: 'Recent',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite),
          label: 'My List',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const SettingsScreen();
      case 2:
        return FavoriteScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }
}


class RecentScreen extends StatelessWidget {
  const RecentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}