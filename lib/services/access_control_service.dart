import 'package:flutter_dotenv/flutter_dotenv.dart';

class AccessControlService {
  AccessControlService._();

  // Mengambil roles dari .env di root
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',').map((e) => e.trim()).toList() ??
      ['Anggota'];

  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  static const String create = actionCreate;
  static const String read = actionRead;
  static const String update = actionUpdate;
  static const String delete = actionDelete;

  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete],
    'Anggota': [actionCreate, actionRead],
    'Asisten': [actionCreate, actionRead, actionUpdate],
  };

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    final String normalizedRole = role.trim();
    final String normalizedAction = action.trim().toLowerCase();

    if (isOwner &&
        (normalizedAction == actionUpdate ||
            normalizedAction == actionDelete)) {
      return true;
    }

    final permissions = _rolePermissions[normalizedRole] ?? [];
    bool hasBasicPermission = permissions.contains(normalizedAction);

    if (normalizedRole == 'Anggota' &&
        (normalizedAction == actionUpdate ||
            normalizedAction == actionDelete)) {
      return isOwner;
    }

    return hasBasicPermission;
  }

  static bool canReadLog(
    String role, {
    required bool isOwner,
    required String visibility,
  }) {
    final String normalizedVisibility = visibility.trim().toLowerCase();
    if (normalizedVisibility == 'private') {
      return isOwner;
    }
    if (normalizedVisibility == 'public') {
      return canPerform(role, actionRead);
    }
    return isOwner;
  }
}
