import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/models/Vehicle.dart';

class VehicleMarkerService extends GetxService {
  final RxSet<Marker> markers = <Marker>{}.obs;
  final BitmapDescriptor _vehicleMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueRed,
  );

  Future<void> buildMarkers(List<VehicleModel> nearbyVehicles) async {
    final Set<Marker> newMarkers = {};

    // Preserve the current user location marker if it was already added
    final currentUserMarkers = markers.where((m) => m.markerId.value == 'current_user');
    newMarkers.addAll(currentUserMarkers);

    for (final vehicle in nearbyVehicles) {
      final location = vehicle.vehicleLocations;
      if (location?.latitude == null || location?.longitude == null) {
        continue;
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(vehicle.id.toString()),
          position: LatLng(location!.latitude!, location.longitude!),
          infoWindow: InfoWindow(
            title: vehicle.vehicleNumber,
            snippet: '${vehicle.brand} ${vehicle.model}',
          ),
          icon: _vehicleMarkerIcon,
        ),
      );
    }

    markers.assignAll(newMarkers);
    markers.refresh(); // Forces GetX to update the Obx widget
  }

Future<void> addCurrentLocationMarker(
  LatLng location,
) async {
  markers.add(
    Marker(
      markerId: const MarkerId('current_user'),
      position: location,
      infoWindow: const InfoWindow(
        title: 'My Location',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      ),
    ),
  );
  markers.refresh(); // Forces GetX to update the Obx widget
}
  void clear() {
    markers.clear();
  }
}
