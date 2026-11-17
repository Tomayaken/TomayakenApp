import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tomayaken_app/services/current_location_service.dart';
import 'package:tomayaken_app/services/shelter_api.dart';
import 'package:tomayaken_app/views/shelters/nearby_shelters_page.dart';
import 'package:tomayaken_app/views/survey/survey_page.dart';

class _Location implements CurrentLocationService {
  LocationProblem? problem;
  Completer<Coordinates>? pending;
  int calls = 0;
  @override
  Future<Coordinates> locate() async {
    calls++;
    if (problem != null) throw LocationFailure(problem!);
    return pending == null ? const Coordinates(35, 139) : await pending!.future;
  }

  @override
  Future<bool> openSettings(LocationProblem problem) async => false;
}

Map<String, Object> _shelter(String name, int distance, bool full) => {
  'name': name,
  'distanceMeters': distance,
  'capacity': 100,
  'currentOccupancy': full ? 120 : 40,
  'isOverCapacity': full,
};

void main() {
  late _Location location;
  late ShelterApi api;
  late int apiCalls;
  late http.Response response;
  setUp(() {
    location = _Location();
    apiCalls = 0;
    response = http.Response.bytes(
      utf8.encode(
        jsonEncode({
          'items': [
            _shelter('遠い避難所', 1500, false),
            _shelter('近い満員の避難所', 100, true),
          ],
        }),
      ),
      200,
    );
    api = ShelterApi(
      baseUrl: 'https://example.test',
      client: MockClient((_) async {
        apiCalls++;
        return response;
      }),
    );
  });
  tearDown(() => api.close());

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NearbySheltersPage(locationService: location, api: api),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('距離の近い順に表示し、満員・人数・直線距離を表示する', (tester) async {
    await open(tester);
    expect(
      tester.getTopLeft(find.text('近い満員の避難所')).dy,
      lessThan(tester.getTopLeft(find.text('遠い避難所')).dy),
    );
    expect(find.text('満員'), findsOneWidget);
    expect(find.text('空きあり'), findsOneWidget);
    expect(find.text('直線距離 100 m'), findsOneWidget);
    expect(find.text('直線距離 1.5 km'), findsOneWidget);
    expect(find.text('滞在人数 120人 / 収容人数 100人'), findsOneWidget);
    expect(apiCalls, 1);
  });

  testWidgets('スマホ幅と大きな文字でも一覧がはみ出さない', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: NearbySheltersPage(locationService: location, api: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('近い満員の避難所'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final problem in [
    LocationProblem.denied,
    LocationProblem.deniedForever,
    LocationProblem.disabled,
  ]) {
    testWidgets('位置情報が利用できない場合はダイアログで案内しAPIを呼ばない: $problem', (tester) async {
      location.problem = problem;
      await open(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(apiCalls, 0);
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      location.problem = null;
      await tester.tap(find.text('再取得'));
      await tester.pumpAndSettle();
      expect(find.text('近い満員の避難所'), findsOneWidget);
      expect(apiCalls, 1);
    });
  }

  testWidgets('取得中に画面を閉じてもAPIを呼ばない', (tester) async {
    location.pending = Completer<Coordinates>();
    await tester.pumpWidget(
      MaterialApp(
        home: NearbySheltersPage(locationService: location, api: api),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    location.pending!.complete(const Coordinates(35, 139));
    await tester.pumpAndSettle();
    expect(apiCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('通信失敗を案内し再取得できる', (tester) async {
    response = http.Response('unavailable', 503);
    await open(tester);
    expect(find.textContaining('避難所情報を取得できませんでした'), findsOneWidget);
    response = http.Response('{"items":[]}', 200);
    await tester.tap(find.text('再取得'));
    await tester.pumpAndSettle();
    expect(find.text('近くの避難所が見つかりませんでした。'), findsOneWidget);
    expect(apiCalls, 2);
    expect(location.calls, 2);
  });

  testWidgets('GPSタイムアウトは通信失敗と区別して案内する', (tester) async {
    location.problem = LocationProblem.timeout;
    await open(tester);
    expect(find.textContaining('現在地の取得に時間がかかっています'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(apiCalls, 0);
  });

  testWidgets('アンケート送信だけではGPS取得や避難所一覧への遷移を開始しない', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SurveyPage()));
    await tester.scrollUntilVisible(
      find.text('送信'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('送信'));
    await tester.pumpAndSettle();
    expect(find.byType(NearbySheltersPage), findsNothing);
    expect(find.byType(SurveyPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
