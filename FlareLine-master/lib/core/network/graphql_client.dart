import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'dart:html' if (dart.library.html) 'package:universal_html/html.dart' as html;

class GraphQLService {

  static const String _graphqlEndpoint = 'http://localhost:3000/graphql';

  static String _getUserAgent() {
    try {
      if (kIsWeb) {
        return html.window.navigator.userAgent;
      } else if (Platform.isAndroid) {
        return 'Flutter/Android';
      } else if (Platform.isIOS) {
        return 'Flutter/iOS';
      }
      return 'Flutter/Unknown';
    } catch (e) {
      print('GraphQLService: ⚠️ Error getting user agent'
            '\n└─ Error: $e');
      return 'Flutter/Unknown';
    }
  }

  static Map<String, String> _getDefaultHeaders() {
    final userAgent = _getUserAgent();
    print(' GraphQLService: 📱 Setting up headers'
          '\n└─ User-Agent: $userAgent');
    
    return {
      'User-Agent': userAgent,
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  static GraphQLClient getClientWithToken(String token) {
    print('GraphQLService: 🔑 Creating authenticated client'
          '\n└─ Has token: ${token.isNotEmpty}');

    final authLink = AuthLink(
      getToken: () => 'Bearer $token',
    );


    final httpLink = HttpLink(
      _graphqlEndpoint,
      defaultHeaders: _getDefaultHeaders(),
    );

    
    print('GraphQLService: 🔗 Setting up GraphQL link'
          '\n└─ Authorization: Bearer ${token.length > 10 ? "${token.substring(0, 10)}..." : token}'
          '\n└─ Endpoint: $_graphqlEndpoint');

    final link = authLink.concat(httpLink);

    return GraphQLClient(
      link: link,
      cache: GraphQLCache(),
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.noCache,
        ),
        mutate: Policies(
          fetch: FetchPolicy.noCache,
        ),
      ),
    );
  }

  static GraphQLClient get client {

    print('GraphQLService: 🌐 Creating unauthenticated client'
          '\n└─ Endpoint: $_graphqlEndpoint');

    final httpLink = HttpLink(
      _graphqlEndpoint,
      defaultHeaders: _getDefaultHeaders(),
    );


    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.noCache,
        ),
        mutate: Policies(
          fetch: FetchPolicy.noCache,
        ),
      ),
    );
  }
}