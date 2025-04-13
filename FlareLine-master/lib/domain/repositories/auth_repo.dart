import 'package:flareline/domain/entities/login_repsonse.dart';


abstract class AuthRepository {
  Future<LoginResponse> login({
    required String email,
    required String password,
  });


}
