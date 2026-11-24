import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/active_disaster.dart';
import '../../services/disaster_api.dart';
import '../shelters/nearby_shelters_page.dart';

/// 災害状態を確認する。ボタンで一覧を開いたときに位置情報を取得する。
/// この監視はアプリ表示中のみ。アプリ終了中の通知受信・GPS取得は行わない。
class DisasterWatch extends StatefulWidget {
  const DisasterWatch({
    super.key,
    required this.child,
    this.api,
    this.shelterBuilder,
    this.pollInterval = const Duration(seconds: 30),
  });

  final Widget child;
  final DisasterApi? api;
  final Widget Function(BuildContext, ActiveDisaster)? shelterBuilder;
  final Duration pollInterval;

  @override
  State<DisasterWatch> createState() => _DisasterWatchState();
}

class _DisasterWatchState extends State<DisasterWatch>
    with WidgetsBindingObserver {
  late final DisasterApi _api;
  Timer? _timer;
  ActiveDisaster? _active;
  Route<void>? _shelterRoute;
  bool _checking = false;
  bool _failed = false;
  bool _checkedOnce = false;
  bool _foreground = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? DisasterApi();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _timer?.cancel();
    if (_foreground) {
      _check();
    } else {
      // 背景移行前に送信したリクエストの応答でGPSを開始しない。
      _generation++;
      _checking = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.api == null) _api.close();
    super.dispose();
  }

  Future<void> _check() async {
    if (!mounted || !_foreground || _checking) return;
    _timer?.cancel();
    final generation = ++_generation;
    setState(() => _checking = true);
    try {
      final disaster = await _api.active();
      if (!mounted || !_foreground || generation != _generation) return;
      final previousDisasterId = _active?.id;
      setState(() {
        _active = disaster;
        _failed = false;
        _checkedOnce = true;
      });
      if (disaster == null || previousDisasterId != disaster.id) {
        // 終了・切り替え時は古い一覧を閉じる。新しい一覧はボタンで開く。
        _closeShelters();
      }
    } catch (_) {
      if (!mounted || !_foreground || generation != _generation) return;
      // 通信失敗を「災害開始」や「災害終了」とみなさない。
      setState(() => _failed = true);
    } finally {
      if (mounted && _foreground && generation == _generation) {
        setState(() => _checking = false);
        // リクエストが完了してから次の確認を予約し、通信を重複させない。
        _timer = Timer(widget.pollInterval, _check);
      }
    }
  }

  void _openShelters(ActiveDisaster disaster) {
    if (_shelterRoute?.isActive ?? false) return;
    final route = MaterialPageRoute<void>(
      builder: (context) =>
          widget.shelterBuilder?.call(context, disaster) ??
          const NearbySheltersPage(),
    );
    _shelterRoute = route;
    Navigator.of(context).push<void>(route).then((_) {
      if (mounted && identical(_shelterRoute, route)) {
        setState(() => _shelterRoute = null);
      }
    });
  }

  void _closeShelters() {
    final route = _shelterRoute;
    _shelterRoute = null;
    if (route != null && route.isActive) {
      final navigator = route.navigator!;
      // 位置情報の案内ダイアログも閉じ、終了済み災害で再取得させない。
      navigator.popUntil((candidate) => identical(candidate, route));
      navigator.removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = _failed
        ? '災害情報を確認できません。通信状態をご確認ください。'
        : _active != null
        ? '災害対応中：${_active!.name}'
        : _checkedOnce
        ? '現在、対応中の災害はありません。'
        : '災害情報を確認しています…';
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(message)),
                  if (_active != null)
                    TextButton(
                      onPressed: () => _openShelters(_active!),
                      child: const Text('避難所一覧'),
                    ),
                  if (_failed)
                    IconButton(
                      tooltip: '災害情報を再確認',
                      onPressed: _checking ? null : _check,
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
