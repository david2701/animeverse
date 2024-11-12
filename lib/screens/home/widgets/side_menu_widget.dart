import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main_app_shell.dart';

class SideMenuWidget extends ConsumerWidget {
  const SideMenuWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExtended = MediaQuery.of(context).size.width >= 1200;
    final selectedIndex = ref.watch(navigationIndexProvider);

    return NavigationRail(
      extended: isExtended,
      backgroundColor: Theme.of(context).primaryColor,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        ref.read(navigationIndexProvider.notifier).state = index;
      },
      destinations: _buildDestinations(),
      selectedIconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: Colors.white.withOpacity(0.7),
        size: 24,
      ),
      labelType: NavigationRailLabelType.selected,
    );
  }

  List<NavigationRailDestination> _buildDestinations() {
    return const [
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
    ];
  }
}