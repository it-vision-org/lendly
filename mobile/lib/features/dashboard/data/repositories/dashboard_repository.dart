import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/dashboard_summary.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardSummary> get() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/dashboard');
      return DashboardSummary.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
