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

  // Backward-compatible aliases for existing call sites.
  static const String create = actionCreate;
  static const String read = actionRead;
  static const String update = actionUpdate;
  static const String delete = actionDelete;

  // Matrix perizinan yang tetap fleksibel
  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete],
    'Anggota': [actionCreate, actionRead],
    'Asisten': [actionRead, actionUpdate],
  };

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    final String normalizedRole = role.trim();
    final String normalizedAction = action.trim().toLowerCase();

    final permissions = _rolePermissions[normalizedRole] ?? [];
    bool hasBasicPermission = permissions.contains(normalizedAction);

    // Logic khusus kepemilikan data (Owner-based RBAC)
    // Anggota bisa update/delete jika dia adalah owner
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
    if (isOwner) {
      return true;
    }

    final String normalizedRole = role.trim();
    if (normalizedRole == 'Ketua') {
      return true;
    }

    final String normalizedVisibility = visibility.trim().toLowerCase();
    return normalizedVisibility == 'public' &&
        canPerform(normalizedRole, actionRead);
  }
}
