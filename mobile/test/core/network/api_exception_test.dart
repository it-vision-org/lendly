import 'package:lendly/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiException.fromDioException', () {
    test('parses the backend ErrorResponse body', () {
      final requestOptions = RequestOptions(
        path: '/transactions/123/repayments',
      );
      final dioException = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {
            'status': 400,
            'code': 'REPAYMENT_EXCEEDS_REMAINING',
            'message': 'Repayment amount cannot exceed the remaining balance',
          },
        ),
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.status, 400);
      expect(apiException.code, 'REPAYMENT_EXCEEDS_REMAINING');
      expect(apiException.isConflict, isFalse);
      expect(apiException.isUnauthorized, isFalse);
    });

    test('falls back to a network error when there is no response body', () {
      final requestOptions = RequestOptions(path: '/auth/login');
      final dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
        message: 'Connection refused',
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.code, 'NETWORK_ERROR');
      expect(apiException.message, 'Connection refused');
    });
  });
}
