import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'views/survey/survey_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveApp(
      title: '避難所ナビ',
      home: SplashScreen(
        nextScreenBuilder: (_) => const SurveyPage(),
      ),
    );
  }
}