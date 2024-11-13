// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import 'widgets/app_bar_widget.dart';
import 'widgets/side_menu_widget.dart';
import 'widgets/featured_anime_widget.dart';
import 'widgets/filter_chips_widget.dart';
import 'widgets/anime_grid_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_isLoadingMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.7) {
      _loadMoreContent();
    }
  }

  Future<void> _loadMoreContent() async {
    if (!ref.read(isLoadingMoreProvider) && ref.read(hasMoreContentProvider)) {
      setState(() => _isLoadingMore = true);

      try {
        // Usamos el método del notifier directamente
        await ref.read(animeListProvider.notifier).loadMoreAnimes();
      } catch (e) {
        debugPrint('Error loading more content: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoadingMore = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          if (isTablet) const SideMenuWidget(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Reiniciar la lista
                ref.invalidate(animeListProvider);
                // Resetear la página
                ref.read(currentPageProvider.notifier).state = 1;
                // Resetear el estado de carga
                ref.read(hasMoreContentProvider.notifier).state = true;
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: const [
                  HomeAppBarWidget(),
                  FilterChipsWidget(),
                  FeaturedAnimeWidget(),
                  AnimeGridWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
