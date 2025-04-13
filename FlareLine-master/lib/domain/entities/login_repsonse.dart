import 'package:flareline/data/models/device_info_model.dart';
import 'package:flareline/domain/entities/user.dart';


class LoginResponse {
  final String? accessToken;
  final String? refreshToken;
  final User user;  // Maintenant nullable
  final bool requiresTwoFactor;
  final String? tempToken;
  final String? sessionId;
  final DeviceInfoModel? deviceInfo;

  LoginResponse({
    this.accessToken,
    this.refreshToken,
     required this.user,  // Plus de required ici
    this.requiresTwoFactor = false,
    this.tempToken,
    this.sessionId,
    this.deviceInfo,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      user: User.fromJson(json['user']) ,
      requiresTwoFactor: json['requiresTwoFactor'] ?? false,
      tempToken: json['tempToken'],
      sessionId: json['sessionId'],
      deviceInfo: json['deviceInfo'] != null 
          ? DeviceInfoModel.fromJson(json['deviceInfo']) 
          : null,
    );
  }
}