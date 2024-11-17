// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
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
    final selectedScraper = ref.watch(selectedScraperProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          if (isTablet) const SideMenuWidget(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(animeListProvider);
                ref.read(currentPageProvider.notifier).state = 1;
                ref.read(hasMoreContentProvider.notifier).state = true;
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    title: Text('Home'),
                    floating: true,
                    actions: [
                      IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          // Toggle search visibility
                          final isSearchVisible = ref.read(isSearchVisibleProvider);
                          ref.read(isSearchVisibleProvider.notifier).state = !isSearchVisible;
                        },
                      ),
                      PopupMenuButton<ScraperProviderOption>(
                        onSelected: (ScraperProviderOption result) {
                          ref.read(selectedScraperProvider.notifier).state = result;
                          ref.invalidate(animeListProvider);
                        },
                        itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<ScraperProviderOption>>[
                          const PopupMenuItem<ScraperProviderOption>(
                            value: ScraperProviderOption.TioAnime,
                            child: Text('TioAnime'),
                          ),
                          const PopupMenuItem<ScraperProviderOption>(
                            value: ScraperProviderOption.FLVAnime,
                            child: Text('FLVAnime'),
                          ),
                        ],
                        icon: Icon(Icons.swap_horiz),
                      ),
                    ],
                  ),
                  const FilterChipsWidget(),
                  const FeaturedAnimeWidget(),
                  const AnimeGridWidget(),
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