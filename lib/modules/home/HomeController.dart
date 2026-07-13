// import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/config/Config.dart';
import 'package:indicab/core/constants/Keys.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/repository/BookingRepository.dart';
import 'package:indicab/core/services/SecureStorageService.dart';
import 'package:indicab/core/services/SocketService.dart';
import 'package:indicab/core/services/StorageService.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/modules/home/HomeService.dart';
import 'package:indicab/modules/home/models/VehicleModels.dart';
import 'package:indicab/modules/home/models/VehicleTypeResponse.dart';

class HomeController extends GetxController {
  HomeController();

  final SecureStorageService _secureStorage = SecureStorageService();
  final StorageService _storage = StorageService();
  final BookingRepository _bookingRepository = BookingRepository(ApiClient());

  static const LatLng defaultPickup = LatLng(12.9756, 77.6050);
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: defaultPickup,
    zoom: 14.5,
  );

  final VehicleCategoryService _vehicleService = VehicleCategoryService();
  final Dio _placesClient = Dio();

  final RxBool isLoading = false.obs;
  final RxBool isAddressLoading = false.obs;
  final RxList<VehicleOption> vehicleTypes = <VehicleOption>[].obs;
  final Rxn<VehicleOption> selectedVehicle = Rxn<VehicleOption>();
  final Rx<LatLng> pickupPoint = defaultPickup.obs;
  final RxString currentAddress = 'MG Road, Bengaluru'.obs;

  // Lat and Lng details
  Rxn<LatLng> pickuplocation = Rxn<LatLng>();
  Rxn<LatLng> droplocation = Rxn<LatLng>();

  // address Details
  RxString pickupAddress = ''.obs;
  RxString dropAddress = ''.obs;

  RxSet<Marker> markers = <Marker>{}.obs;

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

  Future<void> setPickup(dynamic place) async {
    final latlng = LatLng(double.parse(place.lat), double.parse(place.lng));

    pickupPoint.value = latlng;
    pickuplocation.value = latlng;
    pickupAddress.value = place.description ?? '';
    _updateMarkers();
    await _focusMapOnSelectedLocations();
  }

  Future<void> setDrop(dynamic place) async {
    final latlng = LatLng(double.parse(place.lat), double.parse(place.lng));

    droplocation.value = latlng;
    dropAddress.value = place.description ?? '';
    _updateMarkers();
    await _focusMapOnSelectedLocations();
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

  Future<void> _loadHomePage() async {
    await Future.wait([getVehicleType(), refreshAddressFor(pickupPoint.value)]);
  }

  Future<void> _checkActiveRide() async {
    try {
      final token = await _readStoredToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final response = await _bookingRepository.getActiveRide();
      final booking = response.data;

      if (booking == null) {
        return;
      }

      await _socketService.ensureConnected();

      final bookingArgs = <String, dynamic>{
        'booking_no': booking.bookingNo,
        'booking_data': booking,
      };

      if (booking.status == 'started') {
        _redirectToRide(RouteNames.activeRide, bookingArgs);
        return;
      }

      _redirectToRide(RouteNames.rideOtp, bookingArgs);
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
    if (!AppEnv.hasGooglePlacesApiKey) {
      debugPrint('Places key missing or dummy, skipping reverse geocoding');
      currentAddress.value = 'Enable GOOGLE_PLACES_API_KEY for live address';
      return;
    }

    isAddressLoading.value = true;

    try {
      final response = await _placesClient.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${point.latitude},${point.longitude}',
          'key': AppEnv.googlePlacesApiKey,
        },
      );

      final results = response.data['results'] as List<dynamic>? ?? [];
      final firstResult = results.isNotEmpty ? results.first : null;
      final formattedAddress = firstResult is Map<String, dynamic>
          ? firstResult['formatted_address'] as String?
          : null;

      if (formattedAddress != null && formattedAddress.trim().isNotEmpty) {
        currentAddress.value = formattedAddress;
        debugPrint('Reverse geocoded address: $formattedAddress');
      }
    } catch (error) {
      debugPrint('HomeController.refreshAddressFor error: $error');
    } finally {
      isAddressLoading.value = false;
    }
  }

  Future<void> getVehicleType() async {
    try {
      isLoading.value = true;

      final response = await _vehicleService.getAllvehicleCategory(
        page: page,
        limit: limit,
        search: search,
      );

      vehicleTypes.value = response.data.map(_mapVehicleType).toList();
    } catch (error) {
      debugPrint('HomeController.getVehicleType error: $error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    page++;

    try {
      final response = await _vehicleService.getAllvehicleCategory(
        page: page,
        limit: limit,
        search: search,
      );

      vehicleTypes.addAll(response.data.map(_mapVehicleType));
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
  }

  VehicleOption _mapVehicleType(ApiVehicleType vehicle) {
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
