import 'dart:convert';

const _sensitiveKeys = [
  'password',
  'currentPassword',
  'client_secret',
  'access_token',
  'refresh_token',
  'phone',
  'msisdn',
  'mobilenumber',
  'mobile_number',
];

/// Redacts sensitive fields (passwords, tokens, phone numbers, etc.) from
/// network request/response bodies before they're sent to network logging.
///
/// This only affects the copy of the data that gets logged — it never
/// touches the data actually sent to/received from the network.
String redactNetworkBody(dynamic data) {
  if (data is String && data.isEmpty) return data;

  try {
    final decoded = data is String ? jsonDecode(data) : jsonDecode(jsonEncode(data));

    if (decoded is Map<String, dynamic>) {
      _removeSensitiveFields(decoded);
    } else if (decoded is List) {
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          _removeSensitiveFields(item);
        }
      }
    } else if (decoded is String && _isPhoneNumber(decoded)) {
      return jsonEncode('***REDACTED***');
    }

    return jsonEncode(decoded);
  } catch (e) {
    return 'Error parsing body: $e';
  }
}

void _removeSensitiveFields(Map<String, dynamic> map) {
  map.forEach((key, value) {
    final lowerKey = key.toLowerCase();

    if (_sensitiveKeys.any((sensitive) => lowerKey.contains(sensitive))) {
      map[key] = '***REDACTED***';
    } else if (value is String && (_isStripeToken(value) || _isPhoneNumber(value))) {
      map[key] = '***REDACTED***';
    } else if (value is Map<String, dynamic>) {
      _removeSensitiveFields(value);
    } else if (value is List) {
      for (final item in value) {
        if (item is Map<String, dynamic>) {
          _removeSensitiveFields(item);
        }
      }
    }
  });
}

// Detects Stripe tokens (pm_*, client secrets) and JWT bearer tokens
bool _isStripeToken(String value) {
  if (value.startsWith('pm_')) return true;
  if (RegExp('^[a-z]{2,}_[A-Za-z0-9]+_secret_').hasMatch(value)) return true;
  // JWTs always start with base64url-encoded '{"' → eyJ
  if (value.startsWith('eyJ')) return true;
  return false;
}

// Detects E.164-formatted phone numbers (e.g. +447911123456) even when
// logged under a key name that doesn't otherwise flag as sensitive.
bool _isPhoneNumber(String value) {
  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(value);
}
