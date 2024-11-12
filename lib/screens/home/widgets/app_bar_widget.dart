import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';
import '../providers/home_providers.dart';

class HomeAppBarWidget extends ConsumerStatefulWidget {
  const HomeAppBarWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeAppBarWidget> createState() => _HomeAppBarWidgetState();
}

class _HomeAppBarWidgetState extends ConsumerState<HomeAppBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isSearchVisible = ref.watch(isSearchVisibleProvider);
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return SliverAppBar(
      expandedHeight: isSearchVisible ? 80 : 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: isSearchVisible
            ? _buildSearchField()
            : Text(
          'AnimeVerse',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
          ),
        ),
        titlePadding: EdgeInsets.only(
          left: isTablet ? 32 : 16,
          bottom: 16,
          right: 16,
        ),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 300,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search anime...',
          hintStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
      ),
    );
  }

  List<Widget> _buildActions() {
    final isSearchVisible = ref.watch(isSearchVisibleProvider);

    return [
      IconButton(
        icon: Icon(
          isSearchVisible ? Icons.close : Icons.search,
          color: Colors.white,
        ),
        onPressed: _toggleSearch,
      ),
      IconButton(
        icon: const Icon(Icons.filter_list, color: Colors.white),
        onPressed: () => _showFilterBottomSheet(context),
      ),
      const SizedBox(width: 16),
    ];
  }

  void _toggleSearch() {
    final notifier = ref.read(isSearchVisibleProvider.notifier);
    notifier.state = !notifier.state;
    if (!notifier.state) {
      _searchController.clear();
      ref.read(searchQueryProvider.notifier).state = '';
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.7;
    final width = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de arrastre
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Título
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Filtros',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            // Secciones de filtros
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Géneros
                    _buildFilterSection(
                      context,
                      'Géneros',
                      [
                        'Acción',
                        'Aventura',
                        'Comedia',
                        'Drama',
                        'Fantasía',
                        'Terror',
                        'Misterio',
                        'Romance',
                        'Sci-Fi',
                        'Slice of Life',
                        'Deportes',
                        'Sobrenatural',
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Estado
                    _buildFilterSection(
                      context,
                      'Estado',
                      ['En emisión', 'Finalizado', 'Próximamente'],
                    ),
                    const SizedBox(height: 24),
                    // Temporada
                    _buildFilterSection(
                      context,
                      'Temporada',
                      ['Invierno', 'Primavera', 'Verano', 'Otoño'],
                    ),
                  ],
                ),
              ),
            ),
            // Botones de acción
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(selectedGenresProvider.notifier).state = {};
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Limpiar filtros'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
      BuildContext context,
      String title,
      List<String> options,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return Consumer(
              builder: (context, ref, _) {
                final selectedGenres = ref.watch(selectedGenresProvider);
                final isSelected = selectedGenres.contains(option);

                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    final genres = ref.read(selectedGenresProvider);
                    if (selected) {
                      genres.add(option);
                    } else {
                      genres.remove(option);
                    }
                    ref.read(selectedGenresProvider.notifier).state =
                        Set.from(genres);
                  },
                  labelStyle: TextStyle(
                    color: isSelected ?
                    Colors.white :
                    Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}