import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DriverService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  Future<DocumentSnapshot> getDriverProfile(String uid) async {
    return await _firestore.collection('drivers').doc(uid).get();
  }

  Future<void> updateOnlineStatus(bool isOnline, double lat, double lng) async {
    final callable = _functions.httpsCallable('updateDriverLocation');
    await callable.call({
      'latitude': lat,
      'longitude': lng,
      'isOnline': isOnline,
    });
  }

  Future<Map<String, dynamic>> acceptRide(String bookingId, String? requestId) async {
    final callable = _functions.httpsCallable('acceptBooking');
    final res = await callable.call({
      'bookingId': bookingId,
      'requestId': requestId,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> rejectRide(String bookingId, String? requestId) async {
    final callable = _functions.httpsCallable('rejectBooking');
    await callable.call({
      'bookingId': bookingId,
      'requestId': requestId,
      'reason': 'driver_declined',
    });
  }

  Future<void> markDriverArrived(String bookingId) async {
    final callable = _functions.httpsCallable('driverArrived');
    await callable.call({'bookingId': bookingId});
  }

  Future<void> startTrip(String bookingId, String rideOtp) async {
    final callable = _functions.httpsCallable('startTrip');
    await callable.call({
      'bookingId': bookingId,
      'rideOtp': rideOtp,
    });
  }

  Future<Map<String, dynamic>> completeTrip(String bookingId) async {
    final callable = _functions.httpsCallable('completeTrip');
    final res = await callable.call({'bookingId': bookingId});
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final driverServiceProvider = Provider<DriverService>((ref) => DriverService());
