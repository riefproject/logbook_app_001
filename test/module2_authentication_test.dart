import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_001/features/auth/login_controller.dart';

void main() {
  group('Module 2 - Authentication', () {
    late LoginController controller;

    setUp(() {
      controller = LoginController();
    });

    test('login should return user data for valid admin credentials', () {
      final Map<String, dynamic>? actual = controller.login('admin', 'admin123');

      expect(actual, isNotNull);
      expect(actual?['uid'], 'admin');
      expect(actual?['username'], 'admin');
      expect(actual?['role'], 'Ketua');
      expect(actual?['teamId'], 'TIM_ARIEF');
    });

    test('login should normalize username before checking credentials', () {
      final Map<String, dynamic>? actual = controller.login(
        '  ArIeF  ',
        'arief123',
      );

      expect(actual, isNotNull);
      expect(actual?['uid'], 'arief');
      expect(actual?['username'], 'arief');
      expect(actual?['role'], 'Anggota');
      expect(actual?['teamId'], 'TIM_ARIEF');
    });

    test('login should return null for wrong password', () {
      final Map<String, dynamic>? actual = controller.login('admin', 'salah123');

      expect(actual, isNull);
    });

    test('login should return null for unknown username', () {
      final Map<String, dynamic>? actual = controller.login(
        'pengguna-baru',
        'bebas',
      );

      expect(actual, isNull);
    });

    test('login should keep password comparison case-sensitive', () {
      final Map<String, dynamic>? actual = controller.login('dosen', 'DOSEN123');

      expect(actual, isNull);
    });

    test('login result should not expose password field', () {
      final Map<String, dynamic>? actual = controller.login(
        'asisten',
        'asisten123',
      );

      expect(actual, isNotNull);
      expect(actual!.containsKey('password'), isFalse);
    });
  });
}
