class UserSession {
  static String? _userId;
  static String? _role;

  static String? get userId => _userId;
  static String? get role => _role;

  static bool get isLoggedIn => _userId != null && _userId!.trim().isNotEmpty;

  static void setCurrentUser({required String userId, required String role}) {
    _userId = userId.trim();
    _role = role.trim().toLowerCase();
  }

  static void clear() {
    _userId = null;
    _role = null;
  }
}
