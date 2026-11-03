import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomayaken_app/screens/splash_screen.dart';

// アンケート画面の実装に依存しない、テスト専用の遷移先。
class _TestDestination extends StatelessWidget {
  const _TestDestination();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('テスト用遷移先'));
}

Widget _testApp() => MaterialApp(
  home: SplashScreen(nextScreenBuilder: (_) => const _TestDestination()),
);

void main() {
  testWidgets('スプラッシュを2秒間表示し、指定された画面へ戻れない形で遷移する', (tester) async {
    await tester.pumpWidget(_testApp());
    expect(find.text('避難所ナビ'), findsOneWidget);
    expect(find.text('避難支援・情報連携アプリ'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.byType(_TestDestination), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(_TestDestination), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
    expect(await navigator.maybePop(), isFalse);
    await tester.pumpAndSettle();
    expect(find.byType(_TestDestination), findsOneWidget);
  });

  testWidgets('スプラッシュを途中で破棄しても遷移やエラーが発生しない', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(_TestDestination), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
