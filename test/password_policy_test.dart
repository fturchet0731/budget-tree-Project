import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app_project/screens/auth/login_screen.dart';

void main() {
  group('isStrongPassword (mirrors Supabase min 8 + letters_digits)', () {
    test('rejects passwords shorter than 8', () {
      expect(isStrongPassword('abc12'), isFalse);
      expect(isStrongPassword('a1b2c3'), isFalse); // 6 chars
      expect(isStrongPassword(''), isFalse);
    });

    test('rejects 8+ chars with no digit', () {
      expect(isStrongPassword('abcdefgh'), isFalse);
      expect(isStrongPassword('password'), isFalse);
    });

    test('rejects 8+ chars with no letter', () {
      expect(isStrongPassword('12345678'), isFalse);
    });

    test('accepts 8+ chars with a letter and a digit', () {
      expect(isStrongPassword('abcdefg1'), isTrue);
      expect(isStrongPassword('Passw0rd'), isTrue);
      expect(isStrongPassword('tree1234'), isTrue);
    });

    test('the old 6-char minimum no longer passes', () {
      // "abc123" satisfied the previous >= 6 rule; it must now be rejected.
      expect(isStrongPassword('abc123'), isFalse);
    });
  });
}
