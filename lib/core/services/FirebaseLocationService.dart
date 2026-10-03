import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class FirebaseLocationService {
  static final FirebaseLocationService _instance = FirebaseLocationService._internal();
  factory FirebaseLocationService() => _instance;
  FirebaseLocationService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://indicab-ddd95-default-rtdb.firebaseio.com');

  StreamSubscription<DatabaseEvent>? _subscription;
  Function(Map<String, dynamic>)? _onLocationUpdate;
  String? _currentBookingId;

  Future<bool> authenticateWithCustomToken(String customToken) async {
    try {
      await _auth.signInWithCustomToken(customToken);
      return true;
    } catch (e) {
      debugPrint('Firebase Auth Error: $e');
      return false;
    }
  }

  void listenToActiveRide(String bookingId, Function(Map<String, dynamic>) onUpdate) {
    if (_currentBookingId == bookingId) return; // Already listening to this ride
    
    stopListening();
    _currentBookingId = bookingId;
    _onLocationUpdate = onUpdate;

    final ref = _db.ref('active_rides/$bookingId');
    _subscription = ref.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (_onLocationUpdate != null) {
          _onLocationUpdate!(data);
        }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _currentBookingId = null;
    _onLocationUpdate = null;
  }
}
