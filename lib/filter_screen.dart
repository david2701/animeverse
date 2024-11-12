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
    {'value': '0', 'label': 'TV'},
    {'value': '1', 'label': 'Película'},
    {'value': '2', 'label': 'OVA'},
    {'value': '3', 'label': 'Especial'},
  ];

  final List<Map<String, String>> genres = [
    {'value': 'accion', 'label': 'Acción'},
    {'value': 'artes-marciales', 'label': 'Artes Marciales'},
    {'value': 'aventura', 'label': 'Aventuras'},
    {'value': 'carreras', 'label': 'Carreras'},
    {'value': 'ciencia-ficcion', 'label': 'Ciencia Ficción'},
    {'value': 'comedia', 'label': 'Comedia'},
    {'value': 'demencia', 'label': 'Demencia'},
    {'value': 'demonios', 'label': 'Demonios'},
    {'value': 'deportes', 'label': 'Deportes'},
    {'value': 'drama', 'label': 'Drama'},
    {'value': 'ecchi', 'label': 'Ecchi'},
    {'value': 'escolares', 'label': 'Escolares'},
    {'value': 'espacial', 'label': 'Espacial'},
    {'value': 'fantasia', 'label': 'Fantasía'},
    {'value': 'harem', 'label': 'Harem'},
    {'value': 'historico', 'label': 'Historico'},
    {'value': 'infantil', 'label': 'Infantil'},
    {'value': 'josei', 'label': 'Josei'},
    {'value': 'juegos', 'label': 'Juegos'},
    {'value': 'magia', 'label': 'Magia'},
    {'value': 'mecha', 'label': 'Mecha'},
    {'value': 'militar', 'label': 'Militar'},
    {'value': 'misterio', 'label': 'Misterio'},
    {'value': 'musica', 'label': 'Música'},
    {'value': 'parodia', 'label': 'Parodia'},
    {'value': 'policia', 'label': 'Policía'},
    {'value': 'psicologico', 'label': 'Psicológico'},
    {'value': 'recuentos-de-la-vida', 'label': 'Recuentos de la vida'},
    {'value': 'romance', 'label': 'Romance'},
    {'value': 'samurai', 'label': 'Samurai'},
    {'value': 'seinen', 'label': 'Seinen'},
    {'value': 'shoujo', 'label': 'Shoujo'},
    {'value': 'shounen', 'label': 'Shounen'},
    {'value': 'sobrenatural', 'label': 'Sobrenatural'},
    {'value': 'superpoderes', 'label': 'Superpoderes'},
    {'value': 'suspenso', 'label': 'Suspenso'},
    {'value': 'terror', 'label': 'Terror'},
    {'value': 'vampiros', 'label': 'Vampiros'},
    {'value': 'yaoi', 'label': 'Yaoi'},
    {'value': 'yuri', 'label': 'Yuri'},
  ];

  final List<Map<String, String>> statuses = [
    {'value': '2', 'label': 'Finalizado'},
    {'value': '1', 'label': 'En emisión'},
    {'value': '3', 'label': 'Próximamente'},
  ];

  final List<Map<String, String>> sortOptions = [
    {'value': 'recent', 'label': 'Más Reciente'},
    {'value': '-recent', 'label': 'Menos Reciente'},
  ];

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
                Navigator.pop(context, {
                  'types': selectedTypes,
                  'genres': selectedGenres,
                  'yearRange': selectedYearRange,
                  'status': selectedStatus,
                  'sortOrder': selectedSortOrder,
                });
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