import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewWidget extends StatelessWidget {
  final LatLng? pickupLocation;
  final LatLng? dropLocation;
  final Function(LatLng)? onMapTap;
  final Function(GoogleMapController)? onMapCreated;
  final Function(CameraPosition)? onCameraMove;
  final VoidCallback? onCameraIdle;
  final Set<Marker>? markers;
  final Set<Polyline>? polylines;
  final Set<Circle>? circles;
  final double? zoom;
  final MapType? mapType;
  final bool? compassEnabled; 
  final bool? myLocationButtonEnabled;
  
  const MapViewWidget({
    super.key,
    this.pickupLocation,
    this.dropLocation,
    this.onMapTap,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.markers,
    this.polylines,
    this.circles,
    this.zoom,
    this.mapType, 
    this.compassEnabled, 
    this.myLocationButtonEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 1,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: pickupLocation ?? dropLocation ?? const LatLng(0, 0),
          zoom: zoom ?? 10,
        ),
        onMapCreated: onMapCreated,
        onCameraMove: onCameraMove,
        onCameraIdle: onCameraIdle,
        onTap: onMapTap,
        markers: markers ?? {},
        polylines: polylines ?? {},
        circles: circles ?? {},
        mapType: mapType ?? MapType.normal, // Set hybrid as default or pass from parameter
        compassEnabled: compassEnabled ?? true,
        myLocationButtonEnabled: myLocationButtonEnabled ?? true,
      ),
    );
  }
}
