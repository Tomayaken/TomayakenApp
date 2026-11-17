import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/shelter.dart';
import '../services/shelter_service.dart';

class ShelterMapScreen extends StatefulWidget {
  const ShelterMapScreen({
    super.key,
    this.shelterService,
    this.locationService,
  });

  final ShelterService? shelterService;
  final LocationService? locationService;

  @override
  State<ShelterMapScreen> createState() => _ShelterMapScreenState();
}

class _ShelterMapScreenState extends State<ShelterMapScreen> {
  static const _fallbackCenter = LatLng(35.681236, 139.767125);

  late final ShelterService _shelterService;
  late final LocationService _locationService;
  GoogleMapController? _mapController;
  List<Shelter> _shelters = [];
  Position? _currentPosition;
  Shelter? _selectedShelter;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _shelterService = widget.shelterService ?? ShelterService();
    _locationService = widget.locationService ?? LocationService();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    Position? position;
    String? locationError;
    try {
      position = await _locationService.getCurrentPosition();
    } on Exception catch (error) {
      locationError = error.toString();
    }

    try {
      final shelters = await _shelterService.fetchShelters();
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _shelters = shelters;
        _isLoading = false;
        _errorMessage = locationError;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = locationError == null
            ? error.toString()
            : '$locationError\n${error.toString()}';
      });
    }
  }

  Future<void> _selectShelter(Shelter shelter) async {
    setState(() {
      _selectedShelter = shelter;
      _isLoadingDetails = true;
    });
    try {
      final details = await _shelterService.fetchShelter(shelter.id);
      if (!mounted) return;
      setState(() {
        _selectedShelter = details;
        _isLoadingDetails = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingDetails = false;
        _errorMessage = error.toString();
      });
    }
  }

  LatLng get _center {
    final position = _currentPosition;
    return position == null
        ? _fallbackCenter
        : LatLng(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('避難所マップ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 13,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (_) => setState(() => _selectedShelter = null),
                  myLocationEnabled: _currentPosition != null,
                  myLocationButtonEnabled: false,
                  markers: {
                    ..._shelters.map(
                      (shelter) => Marker(
                        markerId: MarkerId(shelter.id),
                        position: LatLng(shelter.latitude, shelter.longitude),
                        infoWindow: InfoWindow(title: shelter.name),
                        onTap: () => _selectShelter(shelter),
                      ),
                    ),
                  },
                ),
                if (_errorMessage != null)
                  _ErrorBanner(
                    message: _errorMessage!,
                    onClose: () => setState(() => _errorMessage = null),
                  ),
                if (_selectedShelter != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _ShelterCard(
                      shelter: _selectedShelter!,
                      isLoading: _isLoadingDetails,
                      onClose: () => setState(() => _selectedShelter = null),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              tooltip: '現在地へ移動',
              onPressed: _mapController == null
                  ? null
                  : () => _mapController!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(target: _center, zoom: 13),
                      ),
                    ),
              child: const Icon(Icons.my_location),
            ),
    );
  }
}

class LocationService {
  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('位置情報サービスを有効にしてください。');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException('位置情報の利用を許可してください。');
    }
    return Geolocator.getCurrentPosition();
  }
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _ShelterCard extends StatelessWidget {
  const _ShelterCard({
    required this.shelter,
    required this.isLoading,
    required this.onClose,
  });

  final Shelter shelter;
  final bool isLoading;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    shelter.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: '閉じる',
                ),
              ],
            ),
            if (shelter.address != null) Text(shelter.address!),
            if (shelter.crowding != null) Text('混雑状況: ${shelter.crowding}'),
            if (shelter.distanceMeters != null)
              Text('距離: ${shelter.distanceMeters!.round()}m'),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        title: Text(message),
        trailing: IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip: '閉じる',
        ),
      ),
    );
  }
}
