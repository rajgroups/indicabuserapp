// import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/config/Config.dart';
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

  final PolylineService _polylineService = PolylineService();

  final TextEditingController originController = TextEditingController();
  final TextEditingController destController = TextEditingController();

  final SocketService _socketService = Get.find<SocketService>();

  @override
  void onClose() {
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

    final token = await _readStoredToken();

    if (token != null) {
      _socketService.setToken(token);
      await _socketService.ensureConnected();
    }
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
    await updateRoutePolyline();
    await _focusMapOnSelectedLocations();
    await getVehicleType();
  }

  Future<void> setDrop(dynamic place) async {
    final latlng = LatLng(double.parse(place.lat), double.parse(place.lng));

    droplocation.value = latlng;
    dropPlaceName.value = place.name;
    dropAddress.value = place.formattedAddress.isNotEmpty
        ? place.formattedAddress
        : place.description;
    dropCoordinates.value = _formatCoordinates(latlng);
    destController.text = dropAddress.value;
    _updateMarkers();
    await updateRoutePolyline();
    await _focusMapOnSelectedLocations();
    await getVehicleType();
  }

  Future<void> updateRoutePolyline({bool forceRefresh = false}) async {
    final pickup = pickuplocation.value ?? pickupPoint.value;
    final drop = droplocation.value;

    if (drop != null) {
      final routeResult = await _polylineService.fetchRoute(
        pickup,
        drop,
        forceRefresh: forceRefresh,
      );
      if (routeResult.points.isNotEmpty) {
        polylines.assignAll({
          Polyline(
            polylineId: const PolylineId('active_route'),
            points: routeResult.points,
            color: const Color(0xFFFFB800),
            width: 5,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
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

    if (drop != null) {
      await PolylineService.launchExternalNavigation(
        destLat: drop.latitude,
        destLng: drop.longitude,
        originLat: pickup.latitude,
        originLng: pickup.longitude,
      );
    }
  }

  void _updateMarkers() {
    markers.clear();

    if (pickuplocation.value != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickuplocation.value!,
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
      );
    }

    if (droplocation.value != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: droplocation.value!,
          infoWindow: const InfoWindow(title: 'Drop'),
        ),
      );
    }

    markers.refresh(); // important
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

      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(south, west),
            northeast: LatLng(north, east),
          ),
          72,
        ),
      );
      return;
    }

    final LatLng? target = drop ?? pickup;
    if (target != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15),
        ),
      );
    }
  }

  GoogleMapController? _mapController;

  int page = 1;
  int limit = 10;
  String search = '';

  Marker get pickupMarker => Marker(
    markerId: const MarkerId('pickup'),
    position: pickupPoint.value,
    infoWindow: InfoWindow(title: currentAddress.value),
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
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: latlng, zoom: 15),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('HomeController.detectAndSetCurrentLocation error: $e');
    }
  }

  Future<void> _loadHomePage() async {
    await detectAndSetCurrentLocation();
    await getVehicleType();
  }

  Future<void> _checkActiveRide() async {
    try {
      final token = await _readStoredToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final response = await _bookingRepository.getActiveRide();
      final booking = response.data;

      activeRide.value = booking;

      if (booking == null) {
        _restorePendingRideFromStorage();
        return;
      }

      await _socketService.ensureConnected();

      final arguments = Get.arguments;
      final fromActiveRide = arguments is Map && arguments['from_active_ride'] == true;

      if (fromActiveRide) {
        return;
      }

      final status = booking.status?.trim().toLowerCase();

      if (status == 'pending' ||
          status == 'no_driver_available' ||
          status == 'expired') {
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
      } else if (status == 'completed') {
        _clearPendingRideState();
        final bookingArgs = <String, dynamic>{
          'booking_no': booking.bookingNo,
          'booking_data': booking,
        };
        _redirectToRide(RouteNames.rideSummary, bookingArgs);
      } else if (status == 'cancelled') {
        _clearPendingRideState();
        activeRide.value = null;
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

  Future<void> onMapTapped(LatLng newPoint) async {
    debugPrint(
      'GoogleMap tap: lat=${newPoint.latitude}, lng=${newPoint.longitude}',
    );
    pickupPoint.value = newPoint;
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLng(newPoint));
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
    final pickup = pickuplocation.value ?? pickupPoint.value;
    final drop = droplocation.value;

    if (drop == null) {
      return 0.0;
    }

    const earthRadiusKm = 6371.0;
    final dLat = (drop.latitude - pickup.latitude) * 3.1415926535897932 / 180.0;
    final dLng = (drop.longitude - pickup.longitude) * 3.1415926535897932 / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(pickup.latitude * 3.1415926535897932 / 180.0) *
            math.cos(drop.latitude * 3.1415926535897932 / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
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
