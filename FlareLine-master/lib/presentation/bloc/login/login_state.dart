import 'package:equatable/equatable.dart';
import 'package:flareline/data/models/device_info_model.dart';
import 'package:flareline/domain/entities/user.dart';


abstract class LoginState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final User user;
  final String? accessToken;
  final String? refreshToken;
  final bool requiresTwoFactor;
  final String? tempToken;
  final String? sessionId;  // Ajout du sessionId
  final DeviceInfoModel? deviceInfo;  // Ajout du deviceInfo

  LoginSuccess({
    required this.user,
    this.accessToken,
    this.refreshToken,
    this.requiresTwoFactor = false,
    this.tempToken,
    this.sessionId, 
    this.deviceInfo,  
  });

  @override
  List<Object?> get props => [
        user,
        accessToken,
        refreshToken,
        requiresTwoFactor,
        tempToken,
        sessionId, 
        deviceInfo,  
      ];
}

class LoginRequires2FA extends LoginState {
  final User user;
  final String tempToken;

   LoginRequires2FA({
    required this.user,
    required this.tempToken,
  }) {
    print('[2025-02-15 16:54:11] 🔐 2FA state initialized'
          '\n└─ User: raednas'
          '\n└─ Email: ${user.email}');
  }

  @override
  List<Object?> get props => [user, tempToken];
}

class LoginFailure extends LoginState {
  final String error;

  LoginFailure(this.error);

  @override
  List<Object> get props => [error];
}

// Optionnel : État pour la vérification 2FA en cours
class TwoFactorVerificationLoading extends LoginState {}
