import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility class providing network-related helper functions
/// for request processing and data manipulation.
class NetworkUtils {
  /// Converts query parameters to URL encoded string
  static String encodeQueryParameters(Map<String, dynamic> parameters) {
    return parameters.entries
        .map((entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
        .join('&');
  }

  /// Parses URL encoded string to map
  static Map<String, String> parseQueryParameters(String queryString) {
    final parameters = <String, String>{};

    if (queryString.isEmpty) return parameters;

    final pairs = queryString.split('&');
    for (final pair in pairs) {
      final keyValue = pair.split('=');
      if (keyValue.length == 2) {
        parameters[Uri.decodeComponent(keyValue[0])] =
            Uri.decodeComponent(keyValue[1]);
      }
    }

    return parameters;
  }

  /// Generates MD5 hash for cache keys
  static String generateCacheKey(String url,
      [Map<String, dynamic>? parameters]) {
    final fullUrl = parameters != null && parameters.isNotEmpty
        ? '$url?${encodeQueryParameters(parameters)}'
        : url;

    return md5.convert(utf8.encode(fullUrl)).toString();
  }

  /// Validates if string is a valid URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.hasAuthority || uri.hasAbsolutePath);
    } catch (_) {
      return false;
    }
  }

  /// Combines base URL with path
  static String combineUrl(String baseUrl, String path) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final pathWithoutSlash = path.startsWith('/') ? path.substring(1) : path;
    return '$base/$pathWithoutSlash';
  }

  /// Formats bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes.bitLength - 1) ~/ 10;

    return '${(bytes / (1 << (i * 10))).toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Sanitizes filename for safe file operations
  static String sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
