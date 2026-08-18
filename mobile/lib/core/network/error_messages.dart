import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Turns any error thrown by the network layer into a short, user-facing
/// message — never a raw exception/stack trace.
String friendlyErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.status == 0) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (error.isUnauthorized) {
      return 'Your session has expired. Please log in again.';
    }
    return error.message;
  }
  if (error is DioException) {
    return friendlyErrorMessage(ApiException.fromDioException(error));
  }
  return 'Something went wrong. Please try again.';
}
