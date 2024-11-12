// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:animeverse/providers.dart';
import 'package:animeverse/screens/home/home_screen.dart';
import 'package:animeverse/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

// Inicializar Hive y obtener las boxes
  final boxes = await initializeHive();
  final userDataBox = boxes[0];
  final animeBox = boxes[1];

  runApp(
    ProviderScope(
      overrides: [
        userDataBoxProvider.overrideWith((ref) => userDataBox),
        animeBoxProvider.overrideWith((ref) => animeBox),
      ],
      child: const AnimeScraperApp(),
    ),
  );
}

Future<List<Box>> initializeHive() async {
  await Hive.initFlutter();

  return await Future.wait([
    Hive.openBox('userDataBox'),
    Hive.openBox('animeBox'),
  ]);
}

class AnimeScraperApp extends ConsumerWidget {
  const AnimeScraperApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);
    final boxes = _verifyBoxes(ref);

// Mostrar loading mientras se inicializan las boxes
    if (!boxes) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Animeverse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }

  bool _verifyBoxes(WidgetRef ref) {
    final userDataBox = ref.watch(userDataBoxProvider);
    final animeBox = ref.watch(animeBoxProvider);
    return userDataBox != null && animeBox != null;
  }
}
