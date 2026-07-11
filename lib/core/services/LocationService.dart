import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  
  static final LocationService _instance = LocationService._internel();
  // final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.();
  factory LocationService() => _instance;  
  LocationService._internel();

  Future<bool> CheckPermission() async{
    bool serviceEnbled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnbled){
      return false;
    }
    
    // Check Location Permission
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
    }

    // return permission
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentLocation() async{
    try {
      if(!await CheckPermission()){
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

    } catch (e) {
      return null;
    }
  }
  
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
 }
