import 'package:flutter/material.dart';

// ===== 仮画面 BEGIN: アンケート画面の統合時にこのファイル全体を削除 =====
// スプラッシュの遷移確認専用。本物のSurveyScreenとして採用しないこと。
// コンフリクト時は共同作成者のアンケート画面を優先する。
class SplashDestinationPlaceholder extends StatelessWidget {
  const SplashDestinationPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アンケート入力')),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'アンケート画面への遷移確認用です。\n入力画面は別途実装されます。',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
// ===== 仮画面 END =====
