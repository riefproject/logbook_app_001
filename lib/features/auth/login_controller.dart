class LoginController {
  final Map<String, Map<String, String>> _users = <String, Map<String, String>>{
    'admin': <String, String>{
      'uid': 'admin',
      'username': 'admin',
      'password': 'admin123',
      'role': 'Ketua',
      'teamId': 'TIM_ARIEF',
    },
    'arief': <String, String>{
      'uid': 'arief',
      'username': 'arief',
      'password': 'arief123',
      'role': 'Anggota',
      'teamId': 'TIM_ARIEF',
    },
    'asisten': <String, String>{
      'uid': 'asisten',
      'username': 'asisten',
      'password': 'asisten123',
      'role': 'Asisten',
      'teamId': 'TIM_ARIEF',
    },
    'dosen': <String, String>{
      'uid': 'dosen',
      'username': 'dosen',
      'password': 'dosen123',
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
