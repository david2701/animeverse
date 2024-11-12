import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';
import '../providers/home_providers.dart';

class FilterChipsWidget extends ConsumerWidget {
  const FilterChipsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGenres = ref.watch(selectedGenresProvider);
    final isSearchVisible = ref.watch(isSearchVisibleProvider);

    if (isSearchVisible) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildFilterChip(context, ref, 'All', selectedGenres.isEmpty),
            ..._buildGenreChips(context, ref, selectedGenres),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGenreChips(
      BuildContext context,
      WidgetRef ref,
      Set<String> selectedGenres,
      ) {
    final genres = [
      'Action',
      'Adventure',
      'Comedy',
      'Drama',
      'Fantasy',
      'Horror',
      'Mystery',
      'Romance',
      'Sci-Fi',
      'Slice of Life',
    ];

    return genres.map((genre) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _buildFilterChip(
          context,
          ref,
          genre,
          selectedGenres.contains(genre),
        ),
      );
    }).toList();
  }

  Widget _buildFilterChip(
      BuildContext context,
      WidgetRef ref,
      String label,
      bool selected,
      ) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Theme.of(context).colorScheme.primary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: Theme.of(context).chipTheme.backgroundColor,
      selectedColor: Theme.of(context).colorScheme.primary,
      onSelected: (bool selected) => _onFilterSelected(ref, label, selected),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected
              ? Colors.transparent
              : Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
    );
  }

  void _onFilterSelected(WidgetRef ref, String label, bool selected) {
    final genres = ref.read(selectedGenresProvider);
    if (label == 'All') {
      ref.read(selectedGenresProvider.notifier).state = {};
    } else {
      if (selected) {
        genres.add(label);
      } else {
        genres.remove(label);
      }
      ref.read(selectedGenresProvider.notifier).state = Set.from(genres);
    }
  }
}