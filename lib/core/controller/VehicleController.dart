import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/models/Vehicle.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/repository/VehicleRepository.dart';
import 'package:indicab/core/services/LocationService.dart';
import 'package:indicab/core/services/VehicleMarkerService.dart';
import 'package:indicab/core/network/network_exceptions.dart';

class Vehiclecontroller extends GetxController {
  static const int _minSearchRadius = 200;
  static const int _maxSearchRadius = 5000000;
  Timer? _debounce;

  Vehiclecontroller({required this.categoryId});

  final VehicleRespository _repository = VehicleRespository(ApiClient());
  final VehicleMarkerService _markerService = Get.put(VehicleMarkerService());
  final int categoryId;
  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;

  Rx<LatLng> currentLocation = const LatLng(0, 0).obs;
  Rx<LatLng> searchCenter = const LatLng(12.9756, 77.6050).obs;
  RxDouble currentZoom = 14.0.obs;
  RxInt searchRadius = 400.obs;
  RxInt activeApiRadius = 400.obs;
  final RxBool isLoading = false.obs;
  final RxList<VehicleModel> nearbyVehicles = <VehicleModel>[].obs;
  RxSet<Marker> get markers => _markerService.markers;
  LocationService locationService = LocationService();

  @override
  void onInit() {
    super.onInit();
    loadLocation();
  }

  Future<void> loadLocation() async {
    final position = await locationService.getCurrentLocation();

    if (position != null) {
      currentLocation.value = LatLng(
        position.latitude,
        position.longitude,
      );
      searchCenter.value = currentLocation.value;

      await _markerService.addCurrentLocationMarker(
        currentLocation.value,
      );

      await fetchNearbyVehicles(
        category: categoryId,
        lat: searchCenter.value.latitude,
        lng: searchCenter.value.longitude,
        radius: searchRadius.value,
      );
      if (_mapController != null) {
        await moveToCurrentLocation();
      }
      return;
    }

    await fetchNearbyVehicles(
      category: categoryId,
      lat: searchCenter.value.latitude,
      lng: searchCenter.value.longitude,
      radius: searchRadius.value,
    );
  }

  Future<void> fetchNearbyVehicles({
    required int category,
    double lat = 12.9756,
    double lng = 77.6050,
    int radius = 400,
  }) async {
    try {
      isLoading.value = true;
      activeApiRadius.value = radius;
      final vehicles = await _repository.getTypeVehicles(
        lat: lat.toDouble(),
        lng: lng.toDouble(),
        radius: (radius / 1000.0).ceil(), // Convert meters to kilometers for the API
        category: category,
      );

      nearbyVehicles.value = vehicles;
      await _markerService.buildMarkers(vehicles);
    } catch (e) {
      if (e is NetworkException && e.statusCode == 401) {
        return;
      }
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void onCameraMove(CameraPosition position) {
    searchCenter.value = position.target;
    currentZoom.value = position.zoom;
    searchRadius.value = _previewRadiusForZoom(position.zoom);
  }

  void onCameraIdle() {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 700),
      () {
        fetchNearbyVehicles(
          category: categoryId,
          lat: searchCenter.value.latitude,
          lng: searchCenter.value.longitude,
          radius: searchRadius.value,
        );
      },
    );
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    if (currentLocation.value.latitude != 0 && currentLocation.value.longitude != 0) {
      moveToCurrentLocation();
    }
  }

  Future<void> moveToCurrentLocation() async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        currentLocation.value,
        16,
      ),
    );
  }

  int _previewRadiusForZoom(double zoom) {
    final calculatedRadius = 350 * math.pow(2, 16 - zoom);
    return calculatedRadius
        .round()
        .clamp(_minSearchRadius, _maxSearchRadius)
        .toInt();
  }
}
