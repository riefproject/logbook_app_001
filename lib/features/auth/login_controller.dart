class LoginController {
  final Map<String, String> _users = {
    'admin': 'admin123',
    'arief': 'arief123',
    'dosen': 'dosen123',
  };

  bool login(String username, String password) {
    final String? registeredPassword = _users[username];
    if (registeredPassword == null) {
      return false;
    }
    return registeredPassword == password;
  }
}
