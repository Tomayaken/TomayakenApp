import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.nextScreenBuilder});

  /// 遷移先は呼び出し元で指定し、アンケート画面の実装とは独立させる。
  final WidgetBuilder nextScreenBuilder;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    // 最初の描画が完了してから、表示時間を計測する。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navigationTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(builder: widget.nextScreenBuilder),
        );
      });
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Icons.health_and_safety_outlined,
                    size: 60,
                    color: colors.primary,
                    semanticLabel: '避難所ナビのロゴ',
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '避難所ナビ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '避難支援・情報連携アプリ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    semanticsLabel: 'アプリを準備しています',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
