// lib/main.dart

import 'package:animeverse/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Open Hive boxes
  final userDataBox = await Hive.openBox('userDataBox');
  final tioAnimeBox = await Hive.openBox('tioAnimeBox');
  final flvAnimeBox = await Hive.openBox('flvAnimeBox');

  runApp(
    ProviderScope(
      overrides: [
        userDataBoxProvider.overrideWithValue(userDataBox),
        tioAnimeBoxProvider.overrideWithValue(tioAnimeBox),
        flvAnimeBoxProvider.overrideWithValue(flvAnimeBox),
      ],
      child: const AnimeScraperApp(),
    ),
  );
}

class AnimeScraperApp extends ConsumerWidget {
  const AnimeScraperApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);

    // Verify that all Hive boxes are initialized
    final boxesInitialized = _verifyBoxes(ref);

    // Show loading indicator while boxes are initializing
    if (!boxesInitialized) {
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
    final tioAnimeBox = ref.watch(tioAnimeBoxProvider);
    final flvAnimeBox = ref.watch(flvAnimeBoxProvider);
    return userDataBox != null && tioAnimeBox != null && flvAnimeBox != null;
  }
}