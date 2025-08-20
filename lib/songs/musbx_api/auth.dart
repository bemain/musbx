import 'package:dio/dio.dart';
import 'package:musbx/keys.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  Future<String?>? _refreshTokenFuture;

  /// Helper for persisting access tokens.
  /// TODO: Use a persistance storage such as FlutterSecureStorage
  static String? accessToken;
  AuthInterceptor(this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (accessToken?.isNotEmpty == true) {
      options.headers["Authorization"] = "Bearer $accessToken";
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isUnauthorized(err) && _shouldRefresh(err.requestOptions)) {
      // Attempt refresh if not already happening
      _refreshTokenFuture ??= _refreshAccessToken();

      final newToken = await _refreshTokenFuture;
      if (newToken != null) {
        // Retry the original request
        final clonedRequest = _retryRequest(err.requestOptions, newToken);
        try {
          final response = await dio.fetch(clonedRequest);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(e as DioException);
        }
      }
    }
    return handler.next(err);
  }

  bool _isUnauthorized(DioException err) {
    return err.response?.statusCode == 401;
  }

  bool _shouldRefresh(RequestOptions requestOptions) {
    // Avoid refreshing again if it"s the refresh token call
    return !requestOptions.path.contains("/token");
  }

  RequestOptions _retryRequest(RequestOptions options, String newToken) {
    // Inject auth
    final newHeaders = Map<String, dynamic>.from(options.headers);
    newHeaders["Authorization"] = "Bearer $newToken";

    if (options.data is FormData) {
      // Clone form data as it cannot be reused
      final FormData oldData = options.data;
      final FormData newData = FormData();

      newData.fields.addAll(oldData.fields);
      for (MapEntry<String, MultipartFile> file in oldData.files) {
        newData.files.add(MapEntry(file.key, file.value.clone()));
      }
      options.data = newData;
    }

    return options.copyWith(headers: newHeaders);
  }

  Future<String?> _refreshAccessToken() async {
    try {
      final response = await dio.post(
        "/token",
        data: {
          "grant_type": "password",
          "username": "user",
          "password": musbxApiKey,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      accessToken = response.data["access_token"];
      return accessToken;
    } catch (e) {
      // If fail, remove token or force user to re-log
      accessToken = null;
      return null;
    } finally {
      // Allow future refresh attempts next time 401 is encountered
      _refreshTokenFuture = null;
    }
  }
}
