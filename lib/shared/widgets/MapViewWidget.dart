import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewWidget extends StatelessWidget {
  final LatLng? pickupLocation;
  final LatLng? dropLocation;
  final Function(LatLng)? onMapTap;
  final Function(GoogleMapController)? onMapCreated;
  final Function(CameraPosition)? onCameraMove;
  final VoidCallback? onCameraMoveStarted;
  final VoidCallback? onCameraIdle;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final Set<Circle>? circles;
  final double? zoom;
  final MapType? mapType;
  final bool? compassEnabled; 
  final bool? myLocationButtonEnabled;
  final bool? zoomGesturesEnabled;
  final bool? scrollGesturesEnabled;
  final bool? rotateGesturesEnabled;
  final bool? tiltGesturesEnabled;
  final bool? myLocationEnabled;
  
  const MapViewWidget({
    super.key,
    this.pickupLocation,
    this.dropLocation,
    this.onMapTap,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraMoveStarted,
    this.onCameraIdle,
    this.markers,
    this.polylines,
    this.circles,
    this.zoom,
    this.mapType, 
    this.compassEnabled, 
    this.myLocationButtonEnabled,
    this.zoomGesturesEnabled,
    this.scrollGesturesEnabled,
    this.rotateGesturesEnabled,
    this.tiltGesturesEnabled,
    this.myLocationEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 1,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: pickupLocation ?? dropLocation ?? const LatLng(12.9756, 77.6050),
          zoom: zoom ?? 15,
        ),
        onMapCreated: onMapCreated,
        onCameraMove: onCameraMove,
        onCameraMoveStarted: onCameraMoveStarted,
        onCameraIdle: onCameraIdle,
        onTap: onMapTap,
        markers: markers ?? {},
        polylines: polylines ?? {},
        circles: circles ?? {},
        mapType: mapType ?? MapType.normal,
        compassEnabled: compassEnabled ?? true,
        myLocationButtonEnabled: myLocationButtonEnabled ?? true,
        zoomGesturesEnabled: zoomGesturesEnabled ?? true,
        scrollGesturesEnabled: scrollGesturesEnabled ?? true,
        rotateGesturesEnabled: rotateGesturesEnabled ?? true,
        tiltGesturesEnabled: tiltGesturesEnabled ?? true,
        myLocationEnabled: myLocationEnabled ?? true,
      ),
    );
  }
}
