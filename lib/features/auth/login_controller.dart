class LoginController {
  final Map<String, Map<String, String>> _users = <String, Map<String, String>>{
    'admin': <String, String>{
      'password': 'admin123',
      'uid': 'admin',
      'username': 'admin',
      'role': 'Ketua',
      'teamId': 'TIM_ARIEF',
    },
    'arief': <String, String>{
      'password': 'arief123',
      'uid': 'arief',
      'username': 'arief',
      'role': 'Anggota',
      'teamId': 'TIM_ARIEF',
    },
    'dosen': <String, String>{
      'password': 'dosen123',
      'uid': 'dosen',
      'username': 'dosen',
      'role': 'Ketua',
      'teamId': 'TIM_ORANG',
    },
  };

  Map<String, dynamic>? login(String username, String password) {
    final String normalizedUsername = username.trim().toLowerCase();
    final Map<String, String>? user = _users[normalizedUsername];
    if (user == null || user['password'] != password) {
      return null;
    }

    return <String, dynamic>{
      'uid': user['uid'] ?? normalizedUsername,
      'username': user['username'] ?? normalizedUsername,
      'role': user['role'] ?? 'Anggota',
      'teamId': user['teamId'] ?? 'unknown',
    };
  }
}
