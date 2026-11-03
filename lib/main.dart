import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
// TODO(survey-integration): 本物のアンケート画面のimportに差し替える。
import 'screens/splash_destination_placeholder.dart';

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
      home: SplashScreen(
        // TODO(survey-integration): 共同作成者のSurveyScreenに差し替える。
        // 統合時は上の仮画面importとsplash_destination_placeholder.dartを削除。
        // コンフリクト時も本物のアンケート画面を採用し、仮画面を残さない。
        nextScreenBuilder: (_) => const SplashDestinationPlaceholder(),
      ),
    );
  }
}
