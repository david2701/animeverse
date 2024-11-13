// lib/screens/filter/filter_screen.dart
import 'package:animeverse/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  List<String> selectedTypes = [];
  List<String> selectedGenres = [];
  RangeValues selectedYearRange = RangeValues(1950, 2024);
  String? selectedStatus;
  String? selectedSortOrder;

  final List<Map<String, String>> types = [
    {'value': 'TV', 'label': 'TV'},
    {'value': 'Película', 'label': 'Película'},
    {'value': 'OVA', 'label': 'OVA'},
    {'value': 'Especial', 'label': 'Especial'},
  ];

  final List<Map<String, String>> genres = [
    {'value': 'Acción', 'label': 'Acción'},
    {'value': 'Artes Marciales', 'label': 'Artes Marciales'},
    {'value': 'Aventuras', 'label': 'Aventuras'},
    {'value': 'Carreras', 'label': 'Carreras'},
    {'value': 'Ciencia Ficción', 'label': 'Ciencia Ficción'},
    {'value': 'Comedia', 'label': 'Comedia'},
    {'value': 'Demencia', 'label': 'Demencia'},
    {'value': 'Demonios', 'label': 'Demonios'},
    {'value': 'Deportes', 'label': 'Deportes'},
    {'value': 'Drama', 'label': 'Drama'},
    {'value': 'Ecchi', 'label': 'Ecchi'},
    {'value': 'Escolares', 'label': 'Escolares'},
    {'value': 'Espacial', 'label': 'Espacial'},
    {'value': 'Fantasía', 'label': 'Fantasía'},
    {'value': 'Harem', 'label': 'Harem'},
    {'value': 'Historico', 'label': 'Histórico'},
    {'value': 'Infantil', 'label': 'Infantil'},
    {'value': 'Josei', 'label': 'Josei'},
    {'value': 'Juegos', 'label': 'Juegos'},
    {'value': 'Magia', 'label': 'Magia'},
    {'value': 'Mecha', 'label': 'Mecha'},
    {'value': 'Militar', 'label': 'Militar'},
    {'value': 'Misterio', 'label': 'Misterio'},
    {'value': 'Música', 'label': 'Música'},
    {'value': 'Parodia', 'label': 'Parodia'},
    {'value': 'Policía', 'label': 'Policía'},
    {'value': 'Psicológico', 'label': 'Psicológico'},
    {'value': 'Recuentos de la vida', 'label': 'Recuentos de la vida'},
    {'value': 'Romance', 'label': 'Romance'},
    {'value': 'Samurai', 'label': 'Samurai'},
    {'value': 'Seinen', 'label': 'Seinen'},
    {'value': 'Shoujo', 'label': 'Shoujo'},
    {'value': 'Shounen', 'label': 'Shounen'},
    {'value': 'Sobrenatural', 'label': 'Sobrenatural'},
    {'value': 'Superpoderes', 'label': 'Superpoderes'},
    {'value': 'Suspenso', 'label': 'Suspenso'},
    {'value': 'Terror', 'label': 'Terror'},
    {'value': 'Vampiros', 'label': 'Vampiros'},
    {'value': 'Yaoi', 'label': 'Yaoi'},
    {'value': 'Yuri', 'label': 'Yuri'},
  ];

  final List<Map<String, String>> statuses = [
    {'value': 'Finalizado', 'label': 'Finalizado'},
    {'value': 'En emisión', 'label': 'En emisión'},
    {'value': 'Próximamente', 'label': 'Próximamente'},
  ];

  final List<Map<String, String>> sortOptions = [
    {'value': 'recent', 'label': 'Más Reciente'},
    {'value': '-recent', 'label': 'Menos Reciente'},
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar los filtros con los valores actuales de los providers
    selectedTypes = List.from(ref.read(selectedTypesProvider));
    selectedGenres = List.from(ref.read(selectedGenresProvider));
    selectedYearRange = ref.read(selectedYearsProvider) ?? RangeValues(1950, 2024);
    selectedStatus = ref.read(selectedStatusProvider);
    selectedSortOrder = ref.read(selectedSortOrderProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildFilterSection(
              title: 'Tipo',
              child: _buildTypeFilters(),
            ),
            _buildFilterSection(
              title: 'Género',
              child: _buildGenreFilters(),
            ),
            _buildFilterSection(
              title: 'Año',
              child: _buildYearFilter(),
            ),
            _buildFilterSection(
              title: 'Estado',
              child: _buildStatusFilter(),
            ),
            _buildFilterSection(
              title: 'Ordenar por',
              child: _buildSortFilter(),
            ),
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedTypes.clear();
                    selectedGenres.clear();
                    selectedYearRange = RangeValues(1950, 2024);
                    selectedStatus = null;
                    selectedSortOrder = null;
                  });

                  // Resetear los providers
                  ref.read(selectedTypesProvider.notifier).state = [];
                  ref.read(selectedGenresProvider.notifier).state = [];
                  ref.read(selectedYearsProvider.notifier).state = null;
                  ref.read(selectedStatusProvider.notifier).state = null;
                  ref.read(selectedSortOrderProvider.notifier).state = null;
                },
                child: const Text('Limpiar todo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildTypeFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = selectedTypes.contains(type['value']);
        return FilterChip(
          label: Text(type['label']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedTypes.add(type['value']!);
              } else {
                selectedTypes.remove(type['value']);
              }
            });
          },
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          checkmarkColor: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildGenreFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((genre) {
        final isSelected = selectedGenres.contains(genre['value']);
        return FilterChip(
          label: Text(genre['label']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                selectedGenres.add(genre['value']!);
              } else {
                selectedGenres.remove(genre['value']);
              }
            });
          },
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
          checkmarkColor: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildYearFilter() {
    return Column(
      children: [
        RangeSlider(
          values: selectedYearRange,
          min: 1950,
          max: 2024,
          divisions: 74,
          labels: RangeLabels(
            selectedYearRange.start.round().toString(),
            selectedYearRange.end.round().toString(),
          ),
          onChanged: (RangeValues values) {
            setState(() {
              selectedYearRange = values;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedYearRange.start.round().toString(),
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                selectedYearRange.end.round().toString(),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      value: selectedStatus,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        hintText: 'Seleccionar estado',
      ),
      items: statuses.map((status) {
        return DropdownMenuItem(
          value: status['value'],
          child: Text(status['label']!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedStatus = value;
        });
      },
    );
  }

  Widget _buildSortFilter() {
    return DropdownButtonFormField<String>(
      value: selectedSortOrder,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        hintText: 'Seleccionar orden',
      ),
      items: sortOptions.map((option) {
        return DropdownMenuItem(
          value: option['value'],
          child: Text(option['label']!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedSortOrder = value;
        });
      },
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Actualizar los providers con los filtros seleccionados
                ref.read(selectedTypesProvider.notifier).state = selectedTypes;
                ref.read(selectedGenresProvider.notifier).state = selectedGenres;
                ref.read(selectedYearsProvider.notifier).state = selectedYearRange;
                ref.read(selectedStatusProvider.notifier).state = selectedStatus;
                ref.read(selectedSortOrderProvider.notifier).state = selectedSortOrder;

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Aplicar filtros'),
            ),
          ),
        ],
      ),
    );
  }
}
