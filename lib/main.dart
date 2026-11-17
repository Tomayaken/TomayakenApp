import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/shelter_map_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '避難所ナビ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563A6)),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      home: SplashScreen(nextScreenBuilder: (_) => const ShelterMapScreen()),
    );
  }
}
