import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockClinicalInterceptor extends Interceptor {
  static const String keySimulatedLatency = 'vitalis_debug_simulated_latency';
  static const String keyForceHttp503 = 'vitalis_debug_force_http_503';

  final Random _random = Random();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final bool enableLatency = prefs.getBool(keySimulatedLatency) ?? true;
    final bool force503 = prefs.getBool(keyForceHttp503) ?? false;

    if (enableLatency) {
      final latencyMs = 400 + _random.nextInt(450); // 400ms - 850ms
      await Future.delayed(Duration(milliseconds: latencyMs));
    }

    if (force503) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 503,
            statusMessage:
                'Clinical Telemetry Vault Gateway Temporarily Unavailable',
            data: {
              'error': 'SERVICE_UNAVAILABLE',
              'message': 'Simulated Recruiter Debug HTTP 503 - Offline Local Cache Active',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    handler.next(options);
  }
}
