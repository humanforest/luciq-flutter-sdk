import 'package:flutter_test/flutter_test.dart';
import 'package:luciq_flutter/src/utils/network_body_redactor.dart';

void main() {
  group('redactNetworkBody', () {
    test('redacts phone number fields', () {
      final body = redactNetworkBody(<String, dynamic>{
        'phoneNumber': '+447911123456',
        'countryCode': 'GB',
      });

      expect(body, contains('"phoneNumber":"***REDACTED***"'));
      expect(body, isNot(contains('+447911123456')));
    });

    test('redacts password and token fields, matching prior behavior', () {
      final body = redactNetworkBody(<String, dynamic>{
        'password': 'secret',
        'access_token': 'abc123',
      });

      expect(body, contains('"password":"***REDACTED***"'));
      expect(body, contains('"access_token":"***REDACTED***"'));
    });

    test('redacts an E.164 phone number logged under an unexpected key', () {
      final body = redactNetworkBody(<String, dynamic>{
        'identifier': '+447911123456',
      });

      expect(body, contains('"identifier":"***REDACTED***"'));
    });

    test('handles a raw JSON string body (as produced by package:http)', () {
      final body = redactNetworkBody('{"phone_number":"+447911123456"}');

      expect(body, contains('"phone_number":"***REDACTED***"'));
      expect(body, isNot(contains('+447911123456')));
    });

    test('leaves an empty string body untouched', () {
      expect(redactNetworkBody(''), '');
    });

    test('does not redact ordinary numeric fields', () {
      final body = redactNetworkBody(<String, dynamic>{'orderId': '123456789'});

      expect(body, contains('"orderId":"123456789"'));
    });
  });
}
