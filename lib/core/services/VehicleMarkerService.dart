import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/models/Vehicle.dart';

class VehicleMarkerService extends GetxService {
  final RxSet<Marker> markers = <Marker>{}.obs;

  // Cache: URL → BitmapDescriptor (avoids re-fetching on every refresh)
  final Map<String, BitmapDescriptor> _iconCache = {};

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    responseType: ResponseType.bytes,
  ));

  // Default fallback marker (green matches Rapido palette)
  BitmapDescriptor get _fallback =>
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

  // ── Build all vehicle markers ───────────────────────────────────────────────
  Future<void> buildMarkers(List<VehicleModel> nearbyVehicles) async {
    final Set<Marker> newMarkers = {};

    // Preserve the current user location marker
    final currentUserMarkers =
        markers.where((m) => m.markerId.value == 'current_user');
    newMarkers.addAll(currentUserMarkers);

    for (final vehicle in nearbyVehicles) {
      final location = vehicle.vehicleLocations;
      if (location?.latitude == null || location?.longitude == null) continue;

      // Prefer category icon → category image → fallback default marker
      final iconUrl = vehicle.categoryIcon ?? vehicle.categoryImage;
      final icon = (iconUrl != null && iconUrl.isNotEmpty)
          ? await _loadNetworkIcon(iconUrl, size: 80)
          : _fallback;

      newMarkers.add(
        Marker(
          markerId: MarkerId(vehicle.id.toString()),
          position: LatLng(location!.latitude!, location.longitude!),
          infoWindow: InfoWindow(
            title: vehicle.vehicleNumber,
            snippet: '${vehicle.brand ?? ''} ${vehicle.model ?? ''}'.trim(),
          ),
          icon: icon,
          anchor: const Offset(0.5, 1.0),
        ),
      );
    }

    markers.assignAll(newMarkers);
    markers.refresh();
  }

  // ── Add user "My Location" marker ──────────────────────────────────────────
  Future<void> addCurrentLocationMarker(LatLng location) async {
    markers.add(
      Marker(
        markerId: const MarkerId('current_user'),
        position: location,
        infoWindow: const InfoWindow(title: 'My Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    markers.refresh();
  }

  void clear() => markers.clear();

  // ── Load a network image URL → BitmapDescriptor ────────────────────────────
  Future<BitmapDescriptor> _loadNetworkIcon(String url, {int size = 80}) async {
    if (_iconCache.containsKey(url)) return _iconCache[url]!;

    try {
      final response = await _dio.get<List<int>>(url);
      if (response.statusCode != 200 || response.data == null) {
        return _fallback;
      }

      final bytes = Uint8List.fromList(response.data!);
      final descriptor = await _bytesToCircularBitmapDescriptor(bytes, size: size);
      if (descriptor != null) {
        _iconCache[url] = descriptor;
        return descriptor;
      }
    } catch (e) {
      debugPrint('[VehicleMarkerService] icon load error for $url : $e');
    }
    return _fallback;
  }

  // ── Render bytes as a circular white-bordered marker icon ──────────────────
  Future<BitmapDescriptor?> _bytesToCircularBitmapDescriptor(
    Uint8List bytes, {
    required int size,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: size,
        targetHeight: size,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final double s = size.toDouble();
      final double pad = s * 0.10;
      final double imgSize = s - pad * 2;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // White drop shadow
      canvas.drawCircle(
        Offset(s / 2, s / 2 + 2),
        s / 2,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.20)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // White background circle
      canvas.drawCircle(
        Offset(s / 2, s / 2),
        s / 2 - 1,
        Paint()..color = Colors.white,
      );

      // Green border (Rapido green)
      canvas.drawCircle(
        Offset(s / 2, s / 2),
        s / 2 - 1,
        Paint()
          ..color = const Color(0xFF00C853)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // Clip to circle and draw the vehicle category image
      canvas.save();
      canvas.clipPath(Path()
        ..addOval(Rect.fromCircle(
            center: Offset(s / 2, s / 2), radius: imgSize / 2)));
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(pad, pad, imgSize, imgSize),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();

      final picture = recorder.endRecording();
      final rendered = await picture.toImage(size, size);
      final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('[VehicleMarkerService] render error: $e');
      return null;
    }
  }
}
