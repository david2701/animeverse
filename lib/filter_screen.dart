import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
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
    return Scaffold(
      appBar: AppBar(title: Text('Filter Animes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.0,
              children: types.map((type) {
                final isSelected = selectedTypes.contains(type['value']);
                return FilterChip(
                  label: Text(type['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      isSelected
                          ? selectedTypes.remove(type['value'])
                          : selectedTypes.add(type['value']!);
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            Text('Género', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.0,
              children: genres.map((genre) {
                final isSelected = selectedGenres.contains(genre['value']);
                return FilterChip(
                  label: Text(genre['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      isSelected
                          ? selectedGenres.remove(genre['value'])
                          : selectedGenres.add(genre['value']!);
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            Text('Año', style: TextStyle(fontWeight: FontWeight.bold)),
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
            SizedBox(height: 20),

            Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              items: statuses.map((status) {
                return DropdownMenuItem(
                  value: status['value'],
                  child: Text(status['label']!),
                );
              }).toList(),
              value: selectedStatus,
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Seleccionar Estado',
              ),
            ),
            SizedBox(height: 20),

            Text('Ordenar', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              items: sortOptions.map((option) {
                return DropdownMenuItem(
                  value: option['value'],
                  child: Text(option['label']!),
                );
              }).toList(),
              value: selectedSortOrder,
              onChanged: (value) {
                setState(() {
                  selectedSortOrder = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Seleccionar Orden',
              ),
            ),
            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Aplica los filtros y regresa con los datos seleccionados
                    Navigator.pop(context, {
                      'types': selectedTypes,
                      'genres': selectedGenres,
                      'yearRange': selectedYearRange,
                      'status': selectedStatus,
                      'sortOrder': selectedSortOrder,
                    });
                  },
                  child: Text('Buscar'),
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
                  child: Text('Limpiar', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
