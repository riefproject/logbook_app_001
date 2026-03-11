class AccessControlService {
  AccessControlService._();

  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Backward-compatible aliases for existing call sites.
  static const String create = actionCreate;
  static const String read = actionRead;
  static const String update = actionUpdate;
  static const String delete = actionDelete;

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    final String normalizedRole = role.trim();
    final String normalizedAction = action.trim().toLowerCase();

    const Set<String> validActions = <String>{
      actionCreate,
      actionRead,
      actionUpdate,
      actionDelete,
    };
    if (!validActions.contains(normalizedAction)) {
      return false;
    }

    if (normalizedRole == 'Ketua') {
      return true;
    }

    if (normalizedRole != 'Anggota') {
      return false;
    }

    if (normalizedAction == actionCreate || normalizedAction == actionRead) {
      return true;
    }

    return isOwner;
  }

  static bool canReadLog(
    String role, {
    required bool isOwner,
    required String visibility,
  }) {
    if (role.trim() == 'Ketua') {
      return true;
    }

    if (isOwner) {
      return true;
    }

    final String normalizedVisibility = visibility.trim().toLowerCase();
    return normalizedVisibility == 'public' && canPerform(role, actionRead);
  }
}
