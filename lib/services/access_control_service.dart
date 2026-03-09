class AccessControlService {
  AccessControlService._();

  static const String create = 'create';
  static const String read = 'read';
  static const String update = 'update';
  static const String delete = 'delete';

  static bool canPerform(String role, String action, {bool isOwner = false}) {
    final String normalizedRole = role.trim();
    final String normalizedAction = action.trim().toLowerCase();

    const Set<String> validActions = <String>{create, read, update, delete};
    if (!validActions.contains(normalizedAction)) {
      return false;
    }

    if (normalizedRole == 'Ketua') {
      return true;
    }

    if (normalizedRole != 'Anggota') {
      return false;
    }

    if (normalizedAction == create || normalizedAction == read) {
      return true;
    }

    return isOwner;
  }
}
