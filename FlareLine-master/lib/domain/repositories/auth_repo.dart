import 'package:dartz/dartz.dart';
import 'package:flareline/domain/entities/login_repsonse.dart';

import '../entities/user.dart';

abstract class AuthRepository {
  Future<LoginResponse> login({
    required String email,
    required String password,
  });


}
