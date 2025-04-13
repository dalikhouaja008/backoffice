

import 'package:flareline/domain/entities/login_repsonse.dart';
import 'package:flareline/domain/entities/user.dart';
import 'package:flareline/domain/repositories/auth_repo.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<LoginResponse> execute({
    required String email,
    required String password,
  }) async {
    return await this.repository.login(email: email, password: password);
  }


  
}

// Classe pour encapsuler le résultat du login
class LoginResult {
  final User user;
  final String accessToken;
  final String refreshToken;

  LoginResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}
