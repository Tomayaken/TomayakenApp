import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tomayaken_app/services/current_location_service.dart';
import 'package:tomayaken_app/services/disaster_api.dart';
import 'package:tomayaken_app/services/shelter_api.dart';
import 'package:tomayaken_app/views/disasters/disaster_watch.dart';
import 'package:tomayaken_app/views/shelters/nearby_shelters_page.dart';

class _Location implements CurrentLocationService {
  int calls = 0;
  LocationProblem? failure;
  Completer<Coordinates>? pending;
  @override
  Future<Coordinates> locate() async {
    calls++;
    if (failure != null) throw LocationFailure(failure!);
    return pending == null ? const Coordinates(35, 139) : await pending!.future;
  }

  @override
  Future<bool> openSettings(LocationProblem problem) async => false;
}

http.Response _active(String id) => http.Response(
  jsonEncode({
    'disaster': {
      'id': id,
      'name': '災害 $id',
      'status': 'active',
      'startedAt': '2026-11-17T00:00:00Z',
      'endedAt': null,
    },
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  late DisasterApi disasters;
  late ShelterApi shelters;
  late _Location location;
  late http.Response response;
  late int disasterCalls;
  late int shelterCalls;
  Completer<http.Response>? pending;

  setUp(() {
    response = http.Response('{"disaster":null}', 200);
    location = _Location();
    disasterCalls = 0;
    shelterCalls = 0;
    pending = null;
    disasters = DisasterApi(
      baseUrl: 'https://example.test',
      client: MockClient((_) async {
        disasterCalls++;
        return pending == null ? response : await pending!.future;
      }),
    );
    shelters = ShelterApi(
      baseUrl: 'https://example.test',
      client: MockClient((_) async {
        shelterCalls++;
        return http.Response('{"items":[]}', 200);
      }),
    );
  });
  tearDown(() {
    disasters.close();
    shelters.close();
  });

  Future<void> open(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: DisasterWatch(
          api: disasters,
          shelterBuilder: (_, _) =>
              NearbySheltersPage(locationService: location, api: shelters),
          child: const Scaffold(body: Text('アンケート画面')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> nextCheck(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
  }

  testWidgets('災害がない間は定期確認してもGPS・避難所APIを呼ばない', (tester) async {
    await open(tester);
    await nextCheck(tester);
    expect(disasterCalls, 2);
    expect(location.calls, 0);
    expect(shelterCalls, 0);
    expect(find.text('現在、対応中の災害はありません。'), findsOneWidget);
    expect(find.text('避難所一覧'), findsNothing);
  });

  testWidgets('災害開始後もアンケートを表示し、ボタンを押したときだけGPS・一覧を取得する', (tester) async {
    await open(tester);
    response = _active('one');
    await nextCheck(tester);
    expect(find.text('アンケート画面'), findsOneWidget);
    expect(find.byType(NearbySheltersPage), findsNothing);
    expect(location.calls, 0);
    expect(shelterCalls, 0);
    await tester.tap(find.text('避難所一覧'));
    await tester.pumpAndSettle();
    expect(find.byType(NearbySheltersPage), findsOneWidget);
    expect(location.calls, 1);
    expect(shelterCalls, 1);
    await nextCheck(tester);
    expect(location.calls, 1);
    expect(shelterCalls, 1);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await nextCheck(tester);
    expect(find.text('アンケート画面'), findsOneWidget);
    expect(location.calls, 1);
    await tester.tap(find.text('避難所一覧'));
    await tester.pumpAndSettle();
    expect(location.calls, 2);
  });

  testWidgets('起動時に災害開始済みでもボタンを押すまでアンケートを表示する', (tester) async {
    response = _active('one');
    await open(tester);
    expect(find.text('アンケート画面'), findsOneWidget);
    expect(find.byType(NearbySheltersPage), findsNothing);
    expect(location.calls, 0);
    expect(shelterCalls, 0);
    await tester.tap(find.text('避難所一覧'));
    await tester.pumpAndSettle();
    expect(location.calls, 1);
    expect(shelterCalls, 1);
  });

  testWidgets('災害終了で一覧を閉じ、新しい災害でもボタンを押して取得する', (tester) async {
    response = _active('one');
    await open(tester);
    await tester.tap(find.text('避難所一覧'));
    await tester.pumpAndSettle();
    response = http.Response('{"disaster":null}', 200);
    await nextCheck(tester);
    expect(find.byType(NearbySheltersPage), findsNothing);
    expect(find.text('アンケート画面'), findsOneWidget);
    response = _active('two');
    await nextCheck(tester);
    expect(find.byType(NearbySheltersPage), findsNothing);
    expect(location.calls, 1);
    await tester.tap(find.text('避難所一覧'));
    await tester.pumpAndSettle();
    expect(location.calls, 2);
    expect(shelterCalls, 2);
  });

  testWidgets('GPS取得中に災害が終了したら取得結果をAPIに送らない', (tester) async {
    location.pending = Completer<Coordinates>();
    await open(tester);
    response = _active('one');
    await nextCheck(tester);
    await tester.tap(find.text('避難所一覧'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(location.calls, 1);
    response = http.Response('{"disaster":null}', 200);
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    location.pending!.complete(const Coordinates(35, 139));
    await tester.pumpAndSettle();
    expect(shelterCalls, 0);
    expect(find.byType(NearbySheltersPage), findsNothing);
  });

  testWidgets('災害終了時は位置情報の案内ダイアログも閉じる', (tester) async {
    location.failure = LocationProblem.denied;
    response = _active('one');
    await open(tester);
    await tester.tap(find.text('避難所一覧'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    response = http.Response('{"disaster":null}', 200);
    await nextCheck(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(NearbySheltersPage), findsNothing);
    expect(shelterCalls, 0);
  });

  testWidgets('通信失敗や復旧で自動取得せず、正常応答後にボタンで開始する', (tester) async {
    response = http.Response('unavailable', 503);
    await open(tester);
    expect(find.textContaining('災害情報を確認できません'), findsOneWidget);
    response = http.Response('{}', 200);
    await nextCheck(tester);
    expect(location.calls, 0);
    response = _active('one');
    await nextCheck(tester);
    expect(location.calls, 0);
    await tester.tap(find.text('避難所一覧'));
    await tester.pumpAndSettle();
    expect(location.calls, 1);
  });

  testWidgets('背景移行後の遅れた開始応答を無視し、復帰時に再確認する', (tester) async {
    pending = Completer<http.Response>();
    await open(tester);
    expect(disasterCalls, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final oldRequest = pending!;
    pending = null;
    oldRequest.complete(_active('one'));
    await tester.pump(const Duration(seconds: 40));
    expect(location.calls, 0);
    expect(disasterCalls, 1);
    response = _active('one');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(disasterCalls, 2);
    expect(location.calls, 0);
    expect(find.text('アンケート画面'), findsOneWidget);
  });

  testWidgets('監視画面を破棄したら確認タイマーを止める', (tester) async {
    await open(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 60));
    expect(disasterCalls, 1);
    expect(location.calls, 0);
    expect(tester.takeException(), isNull);
  });
}
