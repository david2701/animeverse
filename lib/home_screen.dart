
import 'package:animeverse/scraping_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animeverse/providers.dart';
import 'anime_detail_screen.dart';
import 'filter_screen.dart';
import 'model_anime.dart';

// Proveedor para la búsqueda
final searchQueryProvider = StateProvider<String>((ref) => '');

// Proveedor para el estado de carga infinita
final isLoadingMoreProvider = StateProvider<bool>((ref) => false);

// Proveedor para la página actual
final currentPageProvider = StateProvider<int>((ref) => 1);

class HomeScreen extends ConsumerStatefulWidget {
const HomeScreen({Key? key}) : super(key: key);

@override
ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
final ScrollController _scrollController = ScrollController();
final TextEditingController _searchController = TextEditingController();
bool _isSearchExpanded = false;

@override
void initState() {
super.initState();
_scrollController.addListener(_onScroll);
}

void _onScroll() {
if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
_loadMoreData();
}
}

Future<void> _loadMoreData() async {
if (!ref.read(isLoadingMoreProvider)) {
ref.read(isLoadingMoreProvider.notifier).state = true;
final currentPage = ref.read(currentPageProvider);

// Cargar más animes usando el servicio
final animeService = AnimeScraperService();
try {
final newAnimes = await animeService.fetchAllAnimes(page: currentPage + 1);
if (newAnimes.isNotEmpty) {
ref.read(currentPageProvider.notifier).state = currentPage + 1;
// Actualizar la lista de animes en el provider
final currentAnimes = ref.read(animeListProvider).value ?? [];
currentAnimes.addAll(newAnimes);
// Actualizar el cache si es necesario
}
} catch (e) {
print('Error loading more data: $e');
} finally {
ref.read(isLoadingMoreProvider.notifier).state = false;
}
}
}

@override
Widget build(BuildContext context) {
final animeListAsyncValue = ref.watch(animeListProvider);
final searchQuery = ref.watch(searchQueryProvider);
final isTablet = MediaQuery.of(context).size.width >= 600;

return Scaffold(
body: NestedScrollView(
headerSliverBuilder: (context, innerBoxIsScrolled) => [
SliverAppBar(
floating: true,
pinned: true,
expandedHeight: 120,
flexibleSpace: FlexibleSpaceBar(
title: _isSearchExpanded
? _buildSearchField()
    : const Text('Anime List'),
background: Container(
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
Theme.of(context).primaryColor,
Theme.of(context).primaryColor.withOpacity(0.8),
],
),
),
),
),
actions: [
IconButton(
icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
onPressed: () {
setState(() {
_isSearchExpanded = !_isSearchExpanded;
if (!_isSearchExpanded) {
_searchController.clear();
ref.read(searchQueryProvider.notifier).state = '';
}
});
},
),
IconButton(
icon: const Icon(Icons.filter_list),
onPressed: () async {
final result = await Navigator.push(
context,
MaterialPageRoute(builder: (_) => FilterScreen()),
);
if (result != null) {
// Aplicar filtros
}
},
),
],
),
],
body: animeListAsyncValue.when(
data: (animes) {
// Filtrar animes según la búsqueda
final filteredAnimes = animes.where((anime) {
return anime.title.toLowerCase().contains(searchQuery.toLowerCase());
}).toList();

if (filteredAnimes.isEmpty) {
return const Center(
child: Text('No se encontraron resultados'),
);
}

return GridView.builder(
controller: _scrollController,
padding: const EdgeInsets.all(16),
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: isTablet ? 4 : 2,
childAspectRatio: 0.7,
mainAxisSpacing: 16,
crossAxisSpacing: 16,
),
itemCount: filteredAnimes.length + 1, // +1 para el indicador de carga
itemBuilder: (context, index) {
if (index == filteredAnimes.length) {
return ref.watch(isLoadingMoreProvider)
? const Center(child: CircularProgressIndicator())
    : const SizedBox();
}

final anime = filteredAnimes[index];
return _buildAnimeCard(context, anime, isTablet);
},
);
},
loading: () => const Center(child: CircularProgressIndicator()),
error: (error, stack) => Center(
child: Text('Error: $error'),
),
),
),
);
}

Widget _buildSearchField() {
return TextField(
controller: _searchController,
style: const TextStyle(color: Colors.white),
decoration: const InputDecoration(
hintText: 'Buscar anime...',
hintStyle: TextStyle(color: Colors.white70),
border: InputBorder.none,
contentPadding: EdgeInsets.symmetric(horizontal: 16),
),
onChanged: (value) {
ref.read(searchQueryProvider.notifier).state = value;
},
);
}

Widget _buildAnimeCard(BuildContext context, Anime anime, bool isTablet) {
return Card(
elevation: 8,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
),
child: InkWell(
onTap: () => Navigator.push(
context,
MaterialPageRoute(
builder: (_) => AnimeDetailScreen(anime: anime),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Hero(
tag: 'anime_${anime.title}',
child: Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.vertical(
top: Radius.circular(isTablet ? 16 : 12),
),
image: DecorationImage(
image: NetworkImage(anime.coverImageUrl),
fit: BoxFit.cover,
),
),
),
),
),
Padding(
padding: EdgeInsets.all(isTablet ? 16 : 12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
anime.title,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: isTablet ? 16 : 14,
),
),
const SizedBox(height: 8),
Row(
children: [
Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 4,
),
decoration: BoxDecoration(
color: Theme.of(context).primaryColor.withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: Text(
anime.type,
style: TextStyle(
fontSize: isTablet ? 14 : 12,
color: Theme.of(context).primaryColor,
),
),
),
const Spacer(),
Text(
anime.year,
style: TextStyle(
fontSize: isTablet ? 14 : 12,
color: Colors.grey,
),
),
],
),
],
),
),
],
),
),
);
}

@override
void dispose() {
_scrollController.dispose();
_searchController.dispose();
super.dispose();
}
}
