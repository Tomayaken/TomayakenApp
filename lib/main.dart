import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/user_registration_screen.dart';
import 'services/user_identity_service.dart';
import 'services/user_registration_service.dart';
import 'views/survey/survey_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final identityService = UserIdentityService(preferences: preferences);
  final userId = await identityService.getOrCreateUserId();
  runApp(MyApp(userId: userId));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.userId = 'test-user',
    this.registrationService,
  });

  final String userId;
  final UserRegistrationService? registrationService;

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
        nextScreenBuilder: (_) => UserRegistrationScreen(
          userId: userId,
          registrationService: registrationService ?? UserRegistrationService(),
          nextScreenBuilder: (_) => const SurveyPage(),
        ),
      ),
    );
  }
}
