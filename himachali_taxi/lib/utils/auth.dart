import 'package:himachali_taxi/utils/sf_manager.dart';

class AuthService {
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return await SfManager.getToken();
  }

  Future<String?> getUserId() async {
    return await SfManager.getUserId();
  }

  Future<String> getUserRole() async {
    final role = await SfManager.getUserRole();
    return role ?? 'user';
  }

  Future<void> saveAuthData(String token, String userId, String role) async {
    await SfManager.setToken(token);
    await SfManager.setUserId(userId);
    await SfManager.setUserRole(role);
  }
}
