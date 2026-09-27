import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();
  factory ConnectivityService() => instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isChecking = false;

  void initialize() {
    _subscription?.cancel();
    checkConnection();

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _evaluateResults(results);
    });
  }

  Future<bool> checkConnection() async {
    if (_isChecking) return isConnectedNotifier.value;
    _isChecking = true;
    try {
      final results = await _connectivity.checkConnectivity();
      return await _evaluateResults(results);
    } catch (e) {
      debugPrint('[ConnectivityService] check error: $e');
      return isConnectedNotifier.value;
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> _evaluateResults(List<ConnectivityResult> results) async {
    final bool hasInterface = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);

    if (!hasInterface) {
      isConnectedNotifier.value = false;
      return false;
    }

    // Verify actual internet reachability
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isConnectedNotifier.value = true;
        return true;
      }
    } catch (_) {
      // Fallback check
      try {
        final result = await InternetAddress.lookup('cloudflare.com')
            .timeout(const Duration(seconds: 2));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          isConnectedNotifier.value = true;
          return true;
        }
      } catch (_) {}
    }

    isConnectedNotifier.value = false;
    return false;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
