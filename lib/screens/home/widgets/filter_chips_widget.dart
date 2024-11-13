// lib/screens/home/widgets/filter_chips_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';

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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(context, ref, 'All', selectedGenres.isEmpty),
            ),
            ..._buildGenreChips(context, ref, selectedGenres),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGenreChips(
      BuildContext context,
      WidgetRef ref,
      List<String> selectedGenres,
      ) {
    final genres = [
      'Acción',
      'Aventura',
      'Comedia',
      'Drama',
      'Fantasīa',
      'Terror',
      'Misterio',
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
      bool isSelected,
      ) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: FontWeight.w500,
      ),
      selected: isSelected,
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).chipTheme.backgroundColor,
      onSelected: (bool selected) => _onFilterSelected(ref, label, selected),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
    );
  }

  void _onFilterSelected(WidgetRef ref, String label, bool selected) {
    final genres = ref.read(selectedGenresProvider).toList();
    if (label == 'All') {
      ref.read(selectedGenresProvider.notifier).state = [];
    } else {
      if (selected) {
        genres.add(label);
      } else {
        genres.remove(label);
      }
      ref.read(selectedGenresProvider.notifier).state = List.from(genres);
    }
  }
}
