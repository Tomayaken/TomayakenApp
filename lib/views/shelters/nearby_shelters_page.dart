import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/shelter.dart';
import '../../services/current_location_service.dart';
import '../../services/shelter_api.dart';

class NearbySheltersPage extends StatefulWidget {
  const NearbySheltersPage({super.key, this.locationService, this.api});

  final CurrentLocationService? locationService;
  final ShelterApi? api;

  @override
  State<NearbySheltersPage> createState() => _NearbySheltersPageState();
}

class _NearbySheltersPageState extends State<NearbySheltersPage> {
  late final CurrentLocationService _location;
  late final ShelterApi _api;
  bool _loading = false;
  String _progress = '現在地を取得しています…';
  String? _error;
  LocationProblem? _locationProblem;
  Coordinates? _coordinates;
  List<Shelter> _shelters = [];

  @override
  void initState() {
    super.initState();
    _location = widget.locationService ?? DeviceLocationService();
    _api = widget.api ?? ShelterApi();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    if (widget.api == null) _api.close();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _locationProblem = null;
      _coordinates = null;
      _shelters = [];
      _progress = '現在地を取得しています…';
    });
    try {
      final coordinates = await _location.locate();
      if (!mounted) return;
      setState(() {
        _coordinates = coordinates;
        _progress = '近くの避難所を探しています…';
      });
      final shelters = await _api.nearby(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
      );
      if (!mounted) return;
      setState(() => _shelters = shelters);
    } on LocationFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        // 案内ダイアログの背後でもローディングを終了する。
        _loading = false;
        _locationProblem = failure.problem;
        _error = _locationMessage(failure.problem);
      });
      if (failure.problem == LocationProblem.denied ||
          failure.problem == LocationProblem.deniedForever ||
          failure.problem == LocationProblem.disabled) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('位置情報を利用できません'),
            content: Text(_locationMessage(failure.problem)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '避難所情報を取得できませんでした。\n時間をおいて、もう一度お試しください。';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _locationMessage(LocationProblem problem) => switch (problem) {
    LocationProblem.denied || LocationProblem.deniedForever =>
      kIsWeb
          ? '近くの避難所を探すには位置情報の許可が必要です。ブラウザーのサイト設定で位置情報を許可し、再取得してください。'
          : '近くの避難所を探すには位置情報の許可が必要です。端末の設定でこのアプリの位置情報を許可し、再取得してください。',
    LocationProblem.disabled => '端末の位置情報サービスを有効にして、再取得してください。',
    LocationProblem.timeout => '現在地の取得に時間がかかっています。電波の届く場所で再取得してください。',
    LocationProblem.unavailable =>
      '現在地を取得できませんでした。位置情報の設定と通信状態を確認して、再取得してください。',
  };

  Future<void> _openSettings() async {
    final opened = await _location.openSettings(_locationProblem!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? '設定を変更したら、この画面に戻って「再取得」を押してください。'
              : '端末の設定から位置情報の利用を許可してください。',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSettings =
        !kIsWeb &&
        (_locationProblem == LocationProblem.denied ||
            _locationProblem == LocationProblem.deniedForever ||
            _locationProblem == LocationProblem.disabled);
    return Scaffold(
      appBar: AppBar(
        title: const Text('近くの避難所'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: '現在地から再取得',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_progress),
                  ],
                ),
              )
            : _error != null
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 40),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('再取得'),
                      ),
                      if (showSettings)
                        TextButton(
                          onPressed: _openSettings,
                          child: const Text('位置情報の設定を開く'),
                        ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '現在地から近い順 · ${_shelters.length}件',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('距離は直線距離です。実際の経路や受入状況は避難所にご確認ください。'),
                    if (_coordinates != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '現在地：${_coordinates!.latitude.toStringAsFixed(5)}, '
                          '${_coordinates!.longitude.toStringAsFixed(5)}',
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_shelters.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          '近くの避難所が見つかりませんでした。',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    for (final shelter in _shelters)
                      _ShelterCard(shelter: shelter),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ShelterCard extends StatelessWidget {
  const _ShelterCard({required this.shelter});
  final Shelter shelter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final full = shelter.isFull;
    final distance = shelter.distanceMeters < 1000
        ? '${shelter.distanceMeters.round()} m'
        : '${(shelter.distanceMeters / 1000).toStringAsFixed(1)} km';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shelter.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('直線距離 $distance'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: Icon(
                    full
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: full
                        ? colors.onErrorContainer
                        : colors.onPrimaryContainer,
                  ),
                  label: Text(full ? '満員' : '空きあり'),
                  backgroundColor: full
                      ? colors.errorContainer
                      : colors.primaryContainer,
                  labelStyle: TextStyle(
                    color: full
                        ? colors.onErrorContainer
                        : colors.onPrimaryContainer,
                  ),
                ),
                Text(
                  '滞在人数 ${shelter.currentOccupancy}人 / 収容人数 ${shelter.capacity}人',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
