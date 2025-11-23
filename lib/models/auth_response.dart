import 'user_model.dart';

class AuthResponse {
  final String accessToken;
  final UserModel? user;

  AuthResponse({
    required this.accessToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'];
    if (accessToken == null || accessToken is! String) {
      throw Exception('Invalid access_token in response');
    }
    
    return AuthResponse(
      accessToken: accessToken as String,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

