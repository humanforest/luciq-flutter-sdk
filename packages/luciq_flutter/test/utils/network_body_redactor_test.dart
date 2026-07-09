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

    test('does not false-positive redact keys that merely contain "phone" as a substring', () {
      final body = redactNetworkBody(<String, dynamic>{
        'microphoneEnabled': true,
        'headphoneJack': 'present',
      });

      expect(body, contains('"microphoneEnabled":true'));
      expect(body, contains('"headphoneJack":"present"'));
    });

    test('still redacts snake_case and camelCase phone keys via word matching', () {
      final body = redactNetworkBody(<String, dynamic>{
        'phone_number': '+447911123456',
        'contactPhone': '+15551234567',
      });

      expect(body, isNot(contains('+447911123456')));
      expect(body, isNot(contains('+15551234567')));
    });

    test('redacts raw phone numbers in a top-level array', () {
      final body = redactNetworkBody(<dynamic>['+447911123456', 'not-a-phone']);

      expect(body, isNot(contains('+447911123456')));
      expect(body, contains('***REDACTED***'));
      expect(body, contains('not-a-phone'));
    });

    test('keeps a non-JSON plain-text body for diagnostics', () {
      expect(redactNetworkBody('OK'), 'OK');
      expect(redactNetworkBody('<html>Bad Gateway</html>'), '<html>Bad Gateway</html>');
    });

    test('redacts a bare non-JSON phone number instead of erroring', () {
      expect(redactNetworkBody('+447911123456'), '***REDACTED***');
    });

    test('redacts raw phone numbers in a nested array', () {
      final body = redactNetworkBody(<String, dynamic>{
        'recipients': <dynamic>[
          '+447911123456',
          <dynamic>['+15551234567'],
        ],
      });

      expect(body, isNot(contains('+447911123456')));
      expect(body, isNot(contains('+15551234567')));
      expect(body, contains('***REDACTED***'));
    });
  });
}
