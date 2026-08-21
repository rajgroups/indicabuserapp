// import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/config/Config.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/constants/Keys.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/repository/BookingRepository.dart';
import 'package:indicab/core/services/SecureStorageService.dart';
import 'package:indicab/core/services/LocationService.dart';
import 'package:indicab/core/services/PolylineService.dart';
import 'package:indicab/core/services/SocketService.dart';
import 'package:indicab/core/services/StorageService.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/modules/home/HomeService.dart';
import 'package:indicab/modules/home/models/VehicleModels.dart';
import 'package:indicab/modules/home/models/VehicleTypeResponse.dart';
import 'package:indicab/core/models/booking_response.dart';

class DropStopModel {
  final String id;
  Rxn<LatLng> location = Rxn<LatLng>();
  RxString address = ''.obs;
  RxString placeName = ''.obs;
  TextEditingController controller;

  DropStopModel({
    required this.id,
    LatLng? initialLocation,
    String initialAddress = '',
    String initialPlaceName = '',
    TextEditingController? controller,
  }) : controller = controller ?? TextEditingController(text: initialAddress) {
    location.value = initialLocation;
    address.value = initialAddress;
    placeName.value = initialPlaceName;
  }
}

enum LocationSelectionTarget { pickup, drop }

class HomeController extends GetxController {
  HomeController();

  final SecureStorageService _secureStorage = SecureStorageService();
  final StorageService _storage = StorageService();
  final BookingRepository _bookingRepository = BookingRepository(ApiClient());

  final Rxn<BookingDataModel> activeRide = Rxn<BookingDataModel>();

  static const LatLng defaultPickup = LatLng(12.9756, 77.6050);
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: defaultPickup,
    zoom: 14.5,
  );

  final VehicleCategoryService _vehicleService = VehicleCategoryService();

  final RxBool isLoading = false.obs;
  final RxBool isAddressLoading = false.obs;
  final RxList<VehicleOption> vehicleTypes = <VehicleOption>[].obs;
  final Rxn<VehicleOption> selectedVehicle = Rxn<VehicleOption>();
  final Rx<LatLng> pickupPoint = defaultPickup.obs;
  final RxString currentAddress = ''.obs;

  // Location Selection & Dragging Map state
  final Rx<LocationSelectionTarget> locationTarget =
      LocationSelectionTarget.pickup.obs;
  final RxBool isMapDragging = false.obs;
  final RxBool isReverseGeocodingCenter = false.obs;
  final RxString centerPinAddress = ''.obs;
  final RxBool isMapViewMode = false.obs;
  final RxList<String> recentSearches = <String>[
    'MG Road, Bengaluru',
    'Indiranagar 100ft Road, Bengaluru',
    'Koramangala 5th Block, Bengaluru',
    'Kempegowda International Airport, Bengaluru',
  ].obs;
  CameraPosition? lastCameraPosition;
  int _locationCommitVersion = 0;
  LatLng? _dragPreviewPoint;
  LocationSelectionTarget? _dragPreviewTarget;
  Timer? _dragRouteDebounce;
  int _suppressedCameraCallbackDepth = 0;

  void addRecentSearch(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty || trimmed.startsWith('Location (')) return;
    recentSearches.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    recentSearches.insert(0, trimmed);
    if (recentSearches.length > 8) {
      recentSearches.removeLast();
    }
  }

  // Multi-Stop Drop Locations
  final RxList<DropStopModel> dropStops = <DropStopModel>[].obs;
  final RxInt activeDropStopIndex = 0.obs;

  // Lat and Lng details
  Rxn<LatLng> pickuplocation = Rxn<LatLng>();
  Rxn<LatLng> droplocation = Rxn<LatLng>();
  RxString pickupCoordinates = ''.obs;
  RxString dropCoordinates = ''.obs;

  // address Details
  RxString pickupAddress = ''.obs;
  RxString dropAddress = ''.obs;
  RxString pickupPlaceName = ''.obs;
  RxString dropPlaceName = ''.obs;

  RxSet<Marker> markers = <Marker>{}.obs;
  RxSet<Polyline> polylines = <Polyline>{}.obs;
  BitmapDescriptor? _pickupMarkerIcon;
  BitmapDescriptor? _dropMarkerIcon;

  final PolylineService _polylineService = PolylineService();

  final TextEditingController originController = TextEditingController();
  final TextEditingController destController = TextEditingController();

  final SocketService _socketService = Get.find<SocketService>();

  @override
  void onClose() {
    _dragRouteDebounce?.cancel();
    originController.dispose();
    destController.dispose();
    super.onClose();
  }

  @override
  void onInit() async {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    originController.text = "Current Location";
    _ensureInitialDropStop();
    await _loadCustomMarkerIcons();

    final token = await _readStoredToken();

    if (token != null) {
      _socketService.setToken(token);
      await _socketService.ensureConnected();
    }
  }

  Future<T> _runSilentlyWithCameraCallbacks<T>(Future<T> Function() action) async {
    _suppressedCameraCallbackDepth++;
    try {
      return await action();
    } finally {
      _suppressedCameraCallbackDepth--;
    }
  }

  Future<void> _loadCustomMarkerIcons() async {
    _pickupMarkerIcon = await _buildMarker(
      ringColor: const Color(0xFF00C853),
      iconData: Icons.radio_button_checked_rounded,
    );
    _dropMarkerIcon = await _buildMarker(
      ringColor: const Color(0xFFE53935),
      iconData: Icons.location_on_rounded,
    );
    _updateMarkers();
  }

  /// Draws a Rapido-style compact circular map marker:
  /// white disc + colored ring + colored icon, sharp at native DPI.
  Future<BitmapDescriptor> _buildMarker({
    required Color ringColor,
    required IconData iconData,
  }) async {
    const double size = 48.0; // logical px
    final double dpr =
        WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
            ? WidgetsBinding.instance.platformDispatcher.views.first
                .devicePixelRatio
            : 3.0;
    final int px = (size * dpr).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr);

    const double cx = size / 2;
    const double cy = size / 2 - 2;
    const double outerR = 20.0;
    const double innerR = 14.0;

    // Drop shadow
    canvas.drawCircle(
      const Offset(cx, cy + 2),
      outerR,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
    );

    // Outer colored ring
    canvas.drawCircle(
      const Offset(cx, cy),
      outerR,
      Paint()..color = ringColor,
    );

    // White inner disc
    canvas.drawCircle(
      const Offset(cx, cy),
      innerR,
      Paint()..color = Colors.white,
    );

    // Colored icon centered
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 16,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: ringColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - tp.height / 2),
    );

    final img = await recorder.endRecording().toImage(px, px);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }

  LocationSelectionTarget get nextSelectionTarget {
    if (pickuplocation.value == null) {
      return LocationSelectionTarget.pickup;
    }
    if (droplocation.value == null) {
      return LocationSelectionTarget.drop;
    }
    return LocationSelectionTarget.pickup;
  }

  void _ensureInitialDropStop() {
    if (dropStops.isEmpty) {
      dropStops.add(
        DropStopModel(
          id: 'stop_0',
          initialLocation: droplocation.value,
          initialAddress: dropAddress.value,
          initialPlaceName: dropPlaceName.value,
          controller: destController,
        ),
      );
    }
  }

  void addDropStop() {
    _ensureInitialDropStop();
    if (dropStops.length >= 6) {
      Get.snackbar(
        'Maximum Stops Reached',
        'You can add up to 6 drop locations.',
        backgroundColor: AppColors.surface,
      );
      return;
    }
    final index = dropStops.length;
    final newStop = DropStopModel(id: 'stop_$index');
    dropStops.add(newStop);
    activeDropStopIndex.value = index;
    locationTarget.value = LocationSelectionTarget.drop;
  }

  void removeDropStop(int index) {
    if (index < 0 || index >= dropStops.length) return;
    if (dropStops.length <= 1) {
      final stop = dropStops[0];
      stop.location.value = null;
      stop.address.value = '';
      stop.placeName.value = '';
      stop.controller.clear();
      droplocation.value = null;
      dropAddress.value = '';
      dropPlaceName.value = '';
      dropCoordinates.value = '';
      destController.clear();
    } else {
      final removed = dropStops.removeAt(index);
      if (removed.controller != destController) {
        removed.controller.dispose();
      }
      if (activeDropStopIndex.value >= dropStops.length) {
        activeDropStopIndex.value = dropStops.length - 1;
      }
      _syncPrimaryDropWithStops();
    }
    _updateMarkers();
    updateRoutePolyline();
    getVehicleType();
  }

  void setActiveDropStop(int index) {
    _ensureInitialDropStop();
    if (index >= 0 && index < dropStops.length) {
      activeDropStopIndex.value = index;
      locationTarget.value = LocationSelectionTarget.drop;
      final stopLocation = dropStops[index].location.value;
      if (stopLocation != null && _mapController != null) {
        unawaited(
          _runSilentlyWithCameraCallbacks(() async {
            await _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: stopLocation, zoom: 15.5),
              ),
            );
          }),
        );
      }
    }
  }

  void _syncPrimaryDropWithStops() {
    if (dropStops.isEmpty) {
      droplocation.value = null;
      dropAddress.value = '';
      dropPlaceName.value = '';
      dropCoordinates.value = '';
      destController.clear();
      return;
    }

    final validStops =
        dropStops.where((s) => s.location.value != null).toList();
    if (validStops.isNotEmpty) {
      final lastStop = validStops.last;
      droplocation.value = lastStop.location.value;
      dropAddress.value = lastStop.address.value;
      dropPlaceName.value = lastStop.placeName.value;
      dropCoordinates.value =
          _formatCoordinates(lastStop.location.value!);
      destController.text = lastStop.address.value;
    } else {
      droplocation.value = null;
      dropAddress.value = '';
      dropPlaceName.value = '';
      dropCoordinates.value = '';
      destController.clear();
    }
  }

  Future<void> setDropStop(int index, dynamic place) async {
    _ensureInitialDropStop();
    if (index < 0 || index >= dropStops.length) return;
    final latlng = LatLng(double.parse(place.lat), double.parse(place.lng));
    final addr = place.formattedAddress.isNotEmpty
        ? place.formattedAddress
        : place.description;

    final stop = dropStops[index];
    stop.location.value = latlng;
    stop.address.value = addr;
    stop.placeName.value = place.name;
    stop.controller.text = addr;

    _syncPrimaryDropWithStops();
    _updateMarkers();
    await updateRoutePolyline();
    await _focusMapOnSelectedLocations();
    await getVehicleType();
  }

  Future<String?> _readStoredToken() async {
    final secureToken = await _secureStorage.read(StorageKeys.token);
    if (secureToken != null && secureToken.isNotEmpty) {
      final cachedToken = _storage.read(StorageKeys.token);
      if (cachedToken != secureToken) {
        _storage.write(StorageKeys.token, secureToken);
      }
      return secureToken;
    }

    final cachedToken = _storage.read(StorageKeys.token);
    if (cachedToken is String && cachedToken.isNotEmpty) {
      await _secureStorage.write(StorageKeys.token, cachedToken);
      return cachedToken;
    }

    return null;
  }

  void _persistPendingRideState(BookingDataModel booking) {
    final bookingNo = booking.bookingNo?.trim();
    if (bookingNo == null || bookingNo.isEmpty) {
      return;
    }

    _storage.write(StorageKeys.pendingRideBookingNo, bookingNo);

    final vehicleType = booking.categoryName?.trim();
    if (vehicleType != null && vehicleType.isNotEmpty) {
      _storage.write(StorageKeys.pendingRideVehicleType, vehicleType);
    }
  }

  void _clearPendingRideState() {
    _storage.delete(StorageKeys.pendingRideBookingNo);
    _storage.delete(StorageKeys.pendingRideVehicleType);
  }

  void _restorePendingRideFromStorage() {
    if (Get.currentRoute != RouteNames.home) {
      return;
    }

    final bookingNo = _storage.read(StorageKeys.pendingRideBookingNo);
    if (bookingNo is! String || bookingNo.trim().isEmpty) {
      return;
    }

    final vehicleType = _storage.read(StorageKeys.pendingRideVehicleType);
    final arguments = <String, dynamic>{
      'booking_no': bookingNo.trim(),
    };

    if (vehicleType is String && vehicleType.trim().isNotEmpty) {
      arguments['vehicle_type'] = vehicleType.trim();
    }

    _redirectToRide(RouteNames.findingDriver, arguments);
  }

  Future<void> setPickup(dynamic place) async {
    locationTarget.value = LocationSelectionTarget.pickup;
    isMapDragging.value = false;
    isReverseGeocodingCenter.value = false;
    _dragPreviewPoint = null;
    _dragPreviewTarget = null;
    _dragRouteDebounce?.cancel();
    final latlng = LatLng(double.parse(place.lat), double.parse(place.lng));

    pickupPoint.value = latlng;
    pickuplocation.value = latlng;
    pickupPlaceName.value = place.name;
    pickupAddress.value = place.formattedAddress.isNotEmpty
        ? place.formattedAddress
        : place.description;
    pickupCoordinates.value = _formatCoordinates(latlng);
    originController.text = pickupAddress.value;
    _updateMarkers();
    await updateRoutePolyline(forceRefresh: true);
    await _focusMapOnSelectedLocations();
    await getVehicleType();
  }

  Future<void> setDrop(dynamic place) async {
    locationTarget.value = LocationSelectionTarget.drop;
    isMapDragging.value = false;
    isReverseGeocodingCenter.value = false;
    _dragPreviewPoint = null;
    _dragPreviewTarget = null;
    _dragRouteDebounce?.cancel();
    final latlng = LatLng(double.parse(place.lat), double.parse(place.lng));

    droplocation.value = latlng;
    dropPlaceName.value = place.name;
    dropAddress.value = place.formattedAddress.isNotEmpty
        ? place.formattedAddress
        : place.description;
    dropCoordinates.value = _formatCoordinates(latlng);
    destController.text = dropAddress.value;
    _updateMarkers();
    await updateRoutePolyline(forceRefresh: true);
    await _focusMapOnSelectedLocations();
    await getVehicleType();
  }

  LatLng _effectivePickupPoint() {
    final previewActive = isMapViewMode.value &&
        isMapDragging.value &&
        _dragPreviewTarget == LocationSelectionTarget.pickup &&
        _dragPreviewPoint != null;
    return previewActive ? _dragPreviewPoint! : (pickuplocation.value ?? pickupPoint.value);
  }

  LatLng? _effectiveDropPointForMarker() {
    final previewActive = isMapViewMode.value &&
        isMapDragging.value &&
        _dragPreviewTarget == LocationSelectionTarget.drop &&
        _dragPreviewPoint != null;
    return previewActive ? _dragPreviewPoint : droplocation.value;
  }

  List<LatLng> _effectiveDropLocations() {
    final previewActive = isMapViewMode.value &&
        isMapDragging.value &&
        _dragPreviewTarget == LocationSelectionTarget.drop &&
        _dragPreviewPoint != null;

    if (!previewActive || dropStops.isEmpty) {
      return dropStops
          .map((s) => s.location.value)
          .whereType<LatLng>()
          .toList();
    }

    final points = <LatLng>[];
    for (int i = 0; i < dropStops.length; i++) {
      final stop = dropStops[i];
      final pos = i == activeDropStopIndex.value ? _dragPreviewPoint : stop.location.value;
      if (pos != null) {
        points.add(pos);
      }
    }
    if (points.isEmpty && _dragPreviewPoint != null) {
      points.add(_dragPreviewPoint!);
    }
    return points;
  }

  void swapLocations() {
    final tempPickup = pickuplocation.value;
    final tempPickupPlaceName = pickupPlaceName.value;
    final tempPickupAddress = pickupAddress.value;
    final tempPickupCoordinates = pickupCoordinates.value;
    final tempOriginText = originController.text;

    pickuplocation.value = droplocation.value;
    if (droplocation.value != null) {
      pickupPoint.value = droplocation.value!;
    }
    pickupPlaceName.value = dropPlaceName.value;
    pickupAddress.value = dropAddress.value;
    pickupCoordinates.value = dropCoordinates.value;
    originController.text = destController.text;

    droplocation.value = tempPickup;
    dropPlaceName.value = tempPickupPlaceName;
    dropAddress.value = tempPickupAddress;
    dropCoordinates.value = tempPickupCoordinates;
    destController.text = tempOriginText;

    _updateMarkers();
    updateRoutePolyline();
    _focusMapOnSelectedLocations();
    getVehicleType();
  }

  Future<void> updateRoutePolyline({bool forceRefresh = false}) async {
    final pickup = _effectivePickupPoint();
    final validDropLocations = _effectiveDropLocations();

    if (validDropLocations.isEmpty && droplocation.value != null) {
      validDropLocations.add(droplocation.value!);
    }

    if (validDropLocations.isNotEmpty) {
      final List<LatLng> allRoutePoints = [];
      LatLng currentStart = pickup;

      for (final target in validDropLocations) {
        final routeResult = await _polylineService.fetchRoute(
          currentStart,
          target,
          forceRefresh: forceRefresh,
        );
        if (routeResult.points.isNotEmpty) {
          allRoutePoints.addAll(routeResult.points);
        } else {
          allRoutePoints.add(currentStart);
          allRoutePoints.add(target);
        }
        currentStart = target;
      }

      if (allRoutePoints.isNotEmpty) {
        polylines.assignAll({
          Polyline(
            polylineId: const PolylineId('active_route'),
            points: allRoutePoints,
            color: Colors.black,
            width: 5,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
          ),
        });
        polylines.refresh();
      } else {
        polylines.clear();
        polylines.refresh();
      }
    } else {
      polylines.clear();
      polylines.refresh();
    }
  }

  Future<void> launchExternalNavigation() async {
    final pickup = pickuplocation.value ?? pickupPoint.value;
    final drop = droplocation.value;
    if (drop == null) return;

    await PolylineService.launchExternalNavigation(
      destLat: drop.latitude,
      destLng: drop.longitude,
      originLat: pickup.latitude,
      originLng: pickup.longitude,
    );
  }

  void _updateMarkers() {
    markers.clear();

    final activePickup = _effectivePickupPoint();
    final activeDropPoint = _effectiveDropPointForMarker();

    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: activePickup,
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: pickupAddress.value,
        ),
        icon: _pickupMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    if (dropStops.isEmpty && activeDropPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: activeDropPoint,
          anchor: const Offset(0.5, 1.0),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: dropAddress.value,
          ),
          icon: _dropMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    } else {
      for (int i = 0; i < dropStops.length; i++) {
        final stop = dropStops[i];
        final pos = (isMapViewMode.value &&
                isMapDragging.value &&
                _dragPreviewTarget == LocationSelectionTarget.drop &&
                i == activeDropStopIndex.value &&
                _dragPreviewPoint != null)
            ? _dragPreviewPoint
            : stop.location.value;
        if (pos != null) {
          final isLast = i == dropStops.length - 1;
          final title = isLast ? 'Destination' : 'Stop ${i + 1}';
          markers.add(
            Marker(
              markerId: MarkerId('drop_$i'),
              position: pos,
              anchor: const Offset(0.5, 1.0),
              infoWindow: InfoWindow(
                title: title,
                snippet: stop.address.value,
              ),
              icon: _dropMarkerIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }
      }
    }

    markers.refresh();
  }

  Future<void> _focusMapOnSelectedLocations() async {
    if (_mapController == null) {
      return;
    }

    final LatLng? pickup = pickuplocation.value;
    final LatLng? drop = droplocation.value;

    if (pickup != null && drop != null) {
      final double south = pickup.latitude < drop.latitude
          ? pickup.latitude
          : drop.latitude;
      final double north = pickup.latitude > drop.latitude
          ? pickup.latitude
          : drop.latitude;
      final double west = pickup.longitude < drop.longitude
          ? pickup.longitude
          : drop.longitude;
      final double east = pickup.longitude > drop.longitude
          ? pickup.longitude
          : drop.longitude;

      await _runSilentlyWithCameraCallbacks(() async {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(south, west),
              northeast: LatLng(north, east),
            ),
            72,
          ),
        );
      });
      return;
    }

    final LatLng? target = drop ?? pickup;
    if (target != null) {
      await _runSilentlyWithCameraCallbacks(() async {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 15),
          ),
        );
      });
    }
  }

  GoogleMapController? _mapController;

  int page = 1;
  int limit = 10;
  String search = '';

  Marker get pickupMarker => Marker(
    markerId: const MarkerId('pickup'),
    position: pickupPoint.value,
    anchor: const Offset(0.5, 1.0),
    infoWindow: InfoWindow(title: currentAddress.value),
    icon: _pickupMarkerIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  );

  @override
  void onReady() {
    super.onReady();
    debugPrint(
      'HomeController.onReady: mapsKey=${AppEnv.hasGoogleMapsApiKey}, '
      'placesKey=${AppEnv.hasGooglePlacesApiKey}',
    );
    unawaited(_bootstrapHome());
  }

  Future<void> _bootstrapHome() async {
    await _loadHomePage();
    await _checkActiveRide();
  }

  void _setPickupAddressDetails(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return;

    pickupAddress.value = trimmed;
    currentAddress.value = trimmed;
    originController.text = trimmed;

    final parts = trimmed
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      pickupPlaceName.value = parts.take(2).join(', ');
    } else if (parts.isNotEmpty) {
      pickupPlaceName.value = parts.first;
    }
  }

  Future<void> detectAndSetCurrentLocation({bool force = false}) async {
    try {
      final LocationService locationService = LocationService();
      final context = Get.context;
      final position = await locationService.getCurrentLocation(context: context);

      if (position != null) {
        final latlng = LatLng(position.latitude, position.longitude);

        if (!force &&
            pickuplocation.value != null &&
            pickupAddress.value.isNotEmpty) {
          const double earthRadiusMeters = 6371000;
          final dLat = (latlng.latitude - pickuplocation.value!.latitude) * math.pi / 180;
          final dLng = (latlng.longitude - pickuplocation.value!.longitude) * math.pi / 180;
          final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
              math.cos(pickuplocation.value!.latitude * math.pi / 180) *
                  math.cos(latlng.latitude * math.pi / 180) *
                  math.sin(dLng / 2) *
                  math.sin(dLng / 2);
          final distMeters = earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

          if (distMeters < 50) {
            return;
          }
        }

        pickupPoint.value = latlng;
        pickuplocation.value = latlng;
        pickupCoordinates.value = _formatCoordinates(latlng);
        _updateMarkers();

        final address = await _polylineService.reverseGeocode(
          position.latitude,
          position.longitude,
        );

        if (address != null && address.trim().isNotEmpty) {
          _setPickupAddressDetails(address);
        } else if (pickupAddress.value.isEmpty) {
          final dynamicFallback =
              currentAddress.value.isNotEmpty &&
                      !currentAddress.value.startsWith('Enable GOOGLE_')
                  ? currentAddress.value
                  : 'Current Location';
          _setPickupAddressDetails(dynamicFallback);
        }

        if (droplocation.value != null) {
          await updateRoutePolyline();
        }

        if (_mapController != null) {
          await _runSilentlyWithCameraCallbacks(() async {
            await _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: latlng, zoom: 15),
              ),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('HomeController.detectAndSetCurrentLocation error: $e');
    }
  }

  Future<void> moveToCurrentLocation() async {
    if (_mapController != null) {
      try {
        await _runSilentlyWithCameraCallbacks(() async {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: pickupPoint.value, zoom: 15.5),
            ),
          );
        });
      } catch (e) {
        debugPrint('Error animating camera to pickup point: $e');
      }
    }
    await detectAndSetCurrentLocation(force: true);
  }

  Future<void> _loadHomePage() async {
    await detectAndSetCurrentLocation();
    await getVehicleType();
  }

  Future<void> _checkActiveRide() async {
    try {
      final token = await _readStoredToken();
      if (token == null || token.isEmpty) {
        activeRide.value = null;
        return;
      }

      final response = await _bookingRepository.getActiveRide();
      final booking = response.data;

      if (booking == null) {
        // The backend has no active ride for this user, so local pending-ride
        // state is stale and should not force the app back into the ride flow.
        _clearPendingRideState();
        activeRide.value = null;
        return;
      }

      final status = booking.status?.trim().toLowerCase();

      // Non-active statuses: no_driver_available, expired, completed, cancelled
      if (status == 'no_driver_available' ||
          status == 'expired' ||
          status == 'completed' ||
          status == 'cancelled') {
        _clearPendingRideState();
        activeRide.value = null;

        final arguments = Get.arguments;
        final fromActiveRide = arguments is Map && arguments['from_active_ride'] == true;

        if (status == 'completed' && !fromActiveRide) {
          final bookingArgs = <String, dynamic>{
            'booking_no': booking.bookingNo,
            'booking_data': booking,
          };
          _redirectToRide(RouteNames.rideSummary, bookingArgs);
        }
        return;
      }

      activeRide.value = booking;

      await _socketService.ensureConnected();

      final arguments = Get.arguments;
      final fromActiveRide = arguments is Map && arguments['from_active_ride'] == true;

      if (fromActiveRide) {
        return;
      }

      // ONLY 'pending' or 'requested' status should redirect to FindingDriverScreen
      if (status == 'pending' || status == 'requested') {
        _persistPendingRideState(booking);
        final bookingArgs = <String, dynamic>{
          'booking_no': booking.bookingNo,
          'booking_data': booking,
          'vehicle_type': booking.categoryName,
        };
        _redirectToRide(RouteNames.findingDriver, bookingArgs);
      } else if (status == 'accepted' || status == 'arrived' || status == 'started') {
        _clearPendingRideState();
        final bookingArgs = <String, dynamic>{
          'booking_no': booking.bookingNo,
          'booking_data': booking,
        };
        _redirectToRide(RouteNames.activeRide, bookingArgs);
      }
    } catch (error) {
      debugPrint('HomeController._checkActiveRide error: $error');
    }
  }

  void _redirectToRide(String route, Map<String, dynamic> arguments) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == RouteNames.home) {
        Get.offAllNamed(route, arguments: arguments);
      }
    });
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    debugPrint('GoogleMap created successfully');
  }

  void setLocationTarget(LocationSelectionTarget target) {
    locationTarget.value = target;
  }

  void exitLocationSelection() {
    isMapViewMode.value = false;
    isMapDragging.value = false;
    isReverseGeocodingCenter.value = false;
    lastCameraPosition = null;
    _dragPreviewPoint = null;
    _dragPreviewTarget = null;
    _dragRouteDebounce?.cancel();
  }

  void onLocationMapCameraMove(CameraPosition position) {
    if (!isMapViewMode.value || _suppressedCameraCallbackDepth > 0) {
      return;
    }
    lastCameraPosition = position;
    _dragPreviewPoint = position.target;
    _dragPreviewTarget = locationTarget.value;
    if (!isMapDragging.value) {
      isMapDragging.value = true;
    }
    _dragRouteDebounce?.cancel();
    _dragRouteDebounce = Timer(const Duration(milliseconds: 120), () {
      _updateMarkers();
      unawaited(updateRoutePolyline(forceRefresh: true));
    });
  }

  Future<void> onLocationMapCameraIdle() async {
    if (!isMapViewMode.value || _suppressedCameraCallbackDepth > 0) {
      isMapDragging.value = false;
      isReverseGeocodingCenter.value = false;
      return;
    }
    isMapDragging.value = false;
    final targetPoint = lastCameraPosition?.target;
    if (targetPoint == null) return;

    final int commitVersion = ++_locationCommitVersion;
    isReverseGeocodingCenter.value = true;

    // Commit the dragged point immediately so the marker and route stay in sync
    // with the center pin, then enrich the address once geocoding returns.
    if (locationTarget.value == LocationSelectionTarget.pickup) {
      pickupPoint.value = targetPoint;
      pickuplocation.value = targetPoint;
      pickupCoordinates.value = _formatCoordinates(targetPoint);
    } else {
      _ensureInitialDropStop();
      final idx = activeDropStopIndex.value < dropStops.length
          ? activeDropStopIndex.value
          : dropStops.length - 1;
      final stop = dropStops[idx];
      stop.location.value = targetPoint;
      dropCoordinates.value = _formatCoordinates(targetPoint);
      stop.controller.text = stop.address.value.isNotEmpty
          ? stop.address.value
          : stop.controller.text;
      final currentAddressText = stop.address.value;
      if (currentAddressText.isNotEmpty) {
        dropAddress.value = currentAddressText;
      }
    }
    _updateMarkers();
    await updateRoutePolyline(forceRefresh: true);

    try {
      final address = await _polylineService.reverseGeocode(
        targetPoint.latitude,
        targetPoint.longitude,
      );

      if (commitVersion != _locationCommitVersion || !isMapViewMode.value) {
        return;
      }

      if (address != null && address.trim().isNotEmpty) {
        centerPinAddress.value = address;
        if (locationTarget.value == LocationSelectionTarget.pickup) {
          _setPickupAddressDetails(address);
        } else {
          final idx = activeDropStopIndex.value < dropStops.length
              ? activeDropStopIndex.value
              : dropStops.length - 1;
          final stop = dropStops[idx];
          stop.address.value = address;
          stop.controller.text = address;
          final parts = address
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          if (parts.length >= 2) {
            stop.placeName.value = parts.take(2).join(', ');
          } else if (parts.isNotEmpty) {
            stop.placeName.value = parts.first;
          }
          _syncPrimaryDropWithStops();
        }
      }

      _updateMarkers();
      await updateRoutePolyline();
      await getVehicleType();
    } catch (error) {
      debugPrint('HomeController.onLocationMapCameraIdle error: $error');
    } finally {
      if (commitVersion == _locationCommitVersion) {
        isReverseGeocodingCenter.value = false;
      }
      _dragPreviewPoint = null;
      _dragPreviewTarget = null;
    }
  }

  Future<void> onMapTapped(LatLng newPoint) async {
    debugPrint(
      'GoogleMap tap: lat=${newPoint.latitude}, lng=${newPoint.longitude}',
    );
    pickupPoint.value = newPoint;
    if (_mapController != null) {
      await _runSilentlyWithCameraCallbacks(() async {
        await _mapController!.animateCamera(CameraUpdate.newLatLng(newPoint));
      });
    }
    await refreshAddressFor(newPoint);
  }

  Future<void> refreshAddressFor(LatLng point) async {
    isAddressLoading.value = true;

    try {
      final address = await _polylineService.reverseGeocode(
        point.latitude,
        point.longitude,
      );

      if (address != null && address.trim().isNotEmpty) {
        _setPickupAddressDetails(address);
        pickupCoordinates.value = _formatCoordinates(point);
        debugPrint('Reverse geocoded address: $address');
      }
    } catch (error) {
      debugPrint('HomeController.refreshAddressFor error: $error');
    } finally {
      isAddressLoading.value = false;
    }
  }

  String _formatCoordinates(LatLng point) {
    return 'Lat: ${point.latitude.toStringAsFixed(6)}, Lng: ${point.longitude.toStringAsFixed(6)}';
  }

  double calculateDistanceKm() {
    final pickup = _effectivePickupPoint();
    final validDropLocations = _effectiveDropLocations();

    if (validDropLocations.isEmpty) {
      if (droplocation.value != null) {
        validDropLocations.add(droplocation.value!);
      } else {
        return 0.0;
      }
    }

    double totalKm = 0.0;
    LatLng current = pickup;

    for (final target in validDropLocations) {
      const earthRadiusKm = 6371.0;
      final dLat = (target.latitude - current.latitude) * math.pi / 180.0;
      final dLng = (target.longitude - current.longitude) * math.pi / 180.0;
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(current.latitude * math.pi / 180.0) *
              math.cos(target.latitude * math.pi / 180.0) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      totalKm += earthRadiusKm * c;
      current = target;
    }

    return totalKm;
  }

  Future<void> getVehicleType() async {
    try {
      isLoading.value = true;

      final pickup = pickuplocation.value ?? pickupPoint.value;
      final drop = droplocation.value;
      final distanceKm = calculateDistanceKm();

      final response = await _vehicleService.getAllvehicleCategory(
        page: page,
        limit: limit,
        search: search,
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        dropLat: drop?.latitude,
        dropLng: drop?.longitude,
        distanceKm: distanceKm > 0 ? distanceKm : null,
      );

      final mapped = response.data
          .map((v) => _mapVehicleType(v, distanceKm: distanceKm))
          .toList();

      vehicleTypes.value = mapped;

      if (selectedVehicle.value != null) {
        final currentId = selectedVehicle.value!.id;
        final updatedSelected = mapped.firstWhereOrNull((v) => v.id == currentId);
        if (updatedSelected != null) {
          selectedVehicle.value = updatedSelected;
        }
      }
    } catch (error) {
      debugPrint('HomeController.getVehicleType error: $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    page++;

    try {
      final pickup = pickuplocation.value ?? pickupPoint.value;
      final drop = droplocation.value;
      final distanceKm = calculateDistanceKm();

      final response = await _vehicleService.getAllvehicleCategory(
        page: page,
        limit: limit,
        search: search,
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        dropLat: drop?.latitude,
        dropLng: drop?.longitude,
        distanceKm: distanceKm > 0 ? distanceKm : null,
      );

      vehicleTypes.addAll(
        response.data.map((v) => _mapVehicleType(v, distanceKm: distanceKm)),
      );
    } catch (error) {
      debugPrint('HomeController.loadMore error: $error');
    }
  }

  Future<void> searchVehicle(String value) async {
    search = value;
    page = 1;
    await getVehicleType();
  }

  void toggleVehicleSelection(VehicleOption vehicle) {
    if (selectedVehicle.value?.id == vehicle.id) {
      selectedVehicle.value = null;
      return;
    }

    selectedVehicle.value = vehicle;
    unawaited(getVehicleType());
  }

  void selectVehicle(VehicleOption vehicle) {
    selectedVehicle.value = vehicle;
    unawaited(getVehicleType());
  }

  VehicleOption _mapVehicleType(
    ApiVehicleType vehicle, {
    double distanceKm = 0.0,
  }) {
    final fallbackStyle = _fallbackStyleFor(vehicle);

    return VehicleOption(
      id: vehicle.id,
      label: vehicle.label,
      icon: _iconFromApi(vehicle.icon) ?? fallbackStyle.icon,
      accentColor:
          _colorFromHex(vehicle.accentColor) ?? fallbackStyle.accentColor,
      sheetGradient: _gradientFromApi(
        vehicle.sheetGradient,
        fallbackStyle.sheetGradient,
      ),
      tagline: vehicle.tagline,
      startingFare: vehicle.startingFare,
      networkIconUrl: vehicle.iconUrl ?? vehicle.imageUrl,
      subCategories: vehicle.subCategories
          .map(
            (subCategory) => VehicleSubCategory(
              id: subCategory.id,
              name: subCategory.name,
              slug: subCategory.slug,
              price: subCategory.price,
              description: subCategory.description,
              eta: subCategory.eta,
              seats: subCategory.seats,
              estimatedFare: subCategory.estimatedFare ?? subCategory.price,
            ),
          )
          .toList(),
    );
  }

  VehicleOption _fallbackStyleFor(ApiVehicleType vehicle) {
    final lookupKey = [
      vehicle.typeKey,
      vehicle.slug,
      vehicle.label,
      vehicle.icon,
    ].join(' ').toLowerCase();

    if (lookupKey.contains('bike') || lookupKey.contains('two_wheeler')) {
      return const VehicleOption(
        id: 0,
        label: '',
        icon: Icons.two_wheeler_rounded,
        accentColor: Color(0xFF2563EB),
        sheetGradient: [Color(0xFFF4F8FF), Color(0xFFE8F0FF)],
        tagline: '',
        startingFare: '',
        subCategories: [],
      );
    }

    if (lookupKey.contains('car') || lookupKey.contains('sedan')) {
      return const VehicleOption(
        id: 0,
        label: '',
        icon: Icons.directions_car_filled_rounded,
        accentColor: Color(0xFF0F766E),
        sheetGradient: [Color(0xFFF1FFFD), Color(0xFFE2FAF6)],
        tagline: '',
        startingFare: '',
        subCategories: [],
      );
    }

    if (lookupKey.contains('jeep') || lookupKey.contains('suv')) {
      return const VehicleOption(
        id: 0,
        label: '',
        icon: Icons.airport_shuttle_rounded,
        accentColor: Color(0xFF7C3AED),
        sheetGradient: [Color(0xFFF7F2FF), Color(0xFFEEE5FF)],
        tagline: '',
        startingFare: '',
        subCategories: [],
      );
    }

    if (lookupKey.contains('van') || lookupKey.contains('tempo')) {
      return const VehicleOption(
        id: 0,
        label: '',
        icon: Icons.local_shipping_rounded,
        accentColor: Color(0xFFDC6803),
        sheetGradient: [Color(0xFFFFF7ED), Color(0xFFFFEAD5)],
        tagline: '',
        startingFare: '',
        subCategories: [],
      );
    }

    if (lookupKey.contains('bus')) {
      return const VehicleOption(
        id: 0,
        label: '',
        icon: Icons.directions_bus_rounded,
        accentColor: Color(0xFFBE123C),
        sheetGradient: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
        tagline: '',
        startingFare: '',
        subCategories: [],
      );
    }

    if (lookupKey.contains('tractor')) {
      return const VehicleOption(
        id: 0,
        label: '',
        icon: Icons.agriculture_rounded,
        accentColor: Color(0xFF15803D),
        sheetGradient: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
        tagline: '',
        startingFare: '',
        subCategories: [],
      );
    }

    return const VehicleOption(
      id: 0,
      label: '',
      icon: Icons.local_taxi_rounded,
      accentColor: Color(0xFFF5B800),
      sheetGradient: [Color(0xFFFFF7D6), Color(0xFFFFEEA8)],
      tagline: '',
      startingFare: '',
      subCategories: [],
    );
  }

  IconData? _iconFromApi(String value) {
    switch (value.toLowerCase()) {
      case 'two_wheeler':
      case 'two_wheeler_rounded':
      case 'bike':
      case 'bike_rounded':
        return Icons.two_wheeler_rounded;
      case 'directions_car':
      case 'directions_car_filled':
      case 'car':
      case 'car_rounded':
        return Icons.directions_car_filled_rounded;
      case 'airport_shuttle':
      case 'jeep':
      case 'suv':
        return Icons.airport_shuttle_rounded;
      case 'local_shipping':
      case 'van':
      case 'tempo':
        return Icons.local_shipping_rounded;
      case 'directions_bus':
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'agriculture':
      case 'tractor':
        return Icons.agriculture_rounded;
      case 'local_taxi':
      case 'taxi':
        return Icons.local_taxi_rounded;
      default:
        return null;
    }
  }

  Color? _colorFromHex(String value) {
    var hex = value.trim().replaceFirst('#', '');

    if (hex.isEmpty) {
      return null;
    }

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length != 8) {
      return null;
    }

    final parsedColor = int.tryParse(hex, radix: 16);
    if (parsedColor == null) {
      return null;
    }

    return Color(parsedColor);
  }

  List<Color> _gradientFromApi(List<String> values, List<Color> fallback) {
    final colors = values.map(_colorFromHex).whereType<Color>().toList();

    return colors.length >= 2 ? colors : fallback;
  }
}
