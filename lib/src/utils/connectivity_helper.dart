import 'dart:io';

/// Helper class for network connectivity checks
/// Provides methods to verify internet connectivity.
class ConnectivityHelper {
  /// Checks if device has internet connectivity
  /// Returns true if connected, false otherwise
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Checks connectivity to a specific host
  /// [host] - hostname to check
  /// [timeout] - connection timeout duration
  static Future<bool> canReachHost(
    String host, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final result = await InternetAddress.lookup(host).timeout(timeout);
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Performs a ping test to measure network latency
  /// Returns latency in milliseconds or null if failed
  static Future<int?> pingHost(String host) async {
    try {
      final stopwatch = Stopwatch()..start();
      await InternetAddress.lookup(host);
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }
}
