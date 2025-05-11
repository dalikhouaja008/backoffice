import 'dart:convert';
import 'package:flareline/core/services/secure_storage.dart';
import 'package:flareline/data/models/device_info_model.dart';
import 'package:flareline/domain/entities/login_repsonse.dart';
import 'package:flareline/domain/entities/user.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/network/graphql_client.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(String email, String password);

}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
 final GraphQLService graphQLService;
  final SecureStorageService secureStorage;

  AuthRemoteDataSourceImpl({
    required this.graphQLService,  // Injecter GraphQLService au lieu du client
    required this.secureStorage,
  });

 Future<LoginResponse> login(String email, String password) async {
  final timestamp = DateTime.now().toIso8601String();
  print('AuthRemoteDataSourceImpl: 🌐 Sending login request'
        '\n└─ Email: $email'
        '\n└─ Timestamp: $timestamp');

    final GraphQLClient client = GraphQLService.client;

  const String loginMutation = """
    mutation Login(\$credentials: LoginInput!) {
      login(credentials: \$credentials) {
        accessToken
        refreshToken
        tempToken
        requiresTwoFactor
        user {
          _id
          email
          username
          role
          isTwoFactorEnabled
        }
        sessionId
        deviceInfo {
          userAgent
          ip
          device
          browser
          os
        }
      }
    }
  """;

  try {
    final QueryResult result = await client.mutate(
      MutationOptions(
        document: gql(loginMutation),
        variables: {
          "credentials": {
            "email": email,
            "password": password,
          },
        },
      ),
    );

    if (result.hasException) {
      print('AuthRemoteDataSourceImpl: ❌ GraphQL error'
            '\n└─ Error: ${result.exception.toString()}');
      throw Exception(result.exception.toString());
    }

      print('AuthRemoteDataSourceImpl: 📥 Raw GraphQL response:'
          '\n${JsonEncoder.withIndent('  ').convert(result.data)}');

      final loginData = result.data?['login'];
      if (loginData == null) {
        print('[$timestamp] ❌ No login data received');
        throw Exception('No login data received');
      }

      // Vérifier les données utilisateur
      final userData = loginData['user'];
      if (userData == null) {
        print('AuthRemoteDataSourceImpl: ❌ No user data in response');
        throw Exception('No user data in response');
      }

      // Créer l'objet User
      final user = User.fromJson({
        '_id': userData['_id'],
        'email': userData['email'],
        'username': userData['username'],
        'role': userData['role'],
        'isTwoFactorEnabled': userData['isTwoFactorEnabled'] ?? false,
      });

      // Vérifier si 2FA est requis
      final requiresTwoFactor = loginData['requiresTwoFactor'] ?? false;
      if (requiresTwoFactor) {
        final tempToken = loginData['tempToken'];
        if (tempToken == null) {
          print('AuthRemoteDataSourceImpl: ❌ No temp token for 2FA'
              '\n└─ Email: ${user.email}');
          throw Exception('No temporary token provided for 2FA');
        }

        print('AuthRemoteDataSourceImpl: 🔐 2FA required'
            '\n└─ Email: ${user.email}');

        return LoginResponse(
          user: user,
          requiresTwoFactor: true,
          tempToken: tempToken,
          accessToken: null,
          refreshToken: null,
          sessionId: null,
          deviceInfo: null,
        );
      }

      // Vérifier les tokens et la session pour le login normal
      final accessToken = loginData['accessToken'];
      final refreshToken = loginData['refreshToken'];
      final sessionId = loginData['sessionId'];
      final deviceInfoResponse = loginData['deviceInfo'];

      if (accessToken == null || refreshToken == null) {
        print('AuthRemoteDataSourceImpl: ❌ Missing tokens'
            '\n└─ Email: ${user.email}'
            '\n└─ Has access token: ${accessToken != null}'
            '\n└─ Has refresh token: ${refreshToken != null}');
        throw Exception('Missing required tokens');
      }

      // Créer l'objet DeviceInfo
      final deviceInfoModel = deviceInfoResponse != null
          ? DeviceInfoModel.fromJson(deviceInfoResponse)
          : null;

      print('AuthRemoteDataSourceImpl: ✅ Login successful'
          '\n└─ Email: ${user.email}'
          '\n└─ Role: ${user.role}'
          '\n└─ Session ID: $sessionId'
          '\n└─ Device: ${deviceInfoModel?.device ?? "Unknown"}');

      return LoginResponse(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
        requiresTwoFactor: false,
        tempToken: null,
        sessionId: sessionId,
        deviceInfo: deviceInfoModel,
      );
    } catch (e) {
      final errorMessage = 'Failed to login: $e';
      print('AuthRemoteDataSourceImpl: ❌ Login error'
          '\n└─ Error: $errorMessage'
          '\n└─ Email: $email');
      throw Exception(errorMessage);
    }
  }


}
