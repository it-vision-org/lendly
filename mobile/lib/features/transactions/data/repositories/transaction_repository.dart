import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/repayment.dart';
import '../models/transaction.dart';
import '../models/transaction_status.dart';
import '../models/transaction_type.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(dioProvider));
});

final _dateFormat = DateFormat('yyyy-MM-dd');

class TransactionRepository {
  TransactionRepository(this._dio);

  final Dio _dio;

  Future<List<Transaction>> list({TransactionType? type, TransactionStatus? status, String? contactId}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/transactions',
        queryParameters: {
          if (type != null) 'type': type.apiValue,
          if (status != null) 'status': status.apiValue,
          'contactId': ?contactId,
        },
      );
      return response.data!.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Transaction> get(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/transactions/$id');
      return Transaction.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Transaction> create({
    required String contactId,
    required TransactionType type,
    required num amount,
    required String currency,
    String? description,
    required DateTime transactionDate,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/transactions',
        data: {
          'contactId': contactId,
          'type': type.apiValue,
          'amount': amount,
          'currency': currency,
          'description': description,
          'transactionDate': _dateFormat.format(transactionDate),
        },
      );
      return Transaction.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Transaction> update({
    required String id,
    required String contactId,
    required TransactionType type,
    required num amount,
    required String currency,
    String? description,
    required DateTime transactionDate,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/transactions/$id',
        data: {
          'contactId': contactId,
          'type': type.apiValue,
          'amount': amount,
          'currency': currency,
          'description': description,
          'transactionDate': _dateFormat.format(transactionDate),
        },
      );
      return Transaction.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/transactions/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Repayment>> listRepayments(String transactionId) async {
    try {
      final response = await _dio.get<List<dynamic>>('/transactions/$transactionId/repayments');
      return response.data!.map((e) => Repayment.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Repayment> addRepayment({
    required String transactionId,
    required num amount,
    required DateTime paymentDate,
    String? notes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/transactions/$transactionId/repayments',
        data: {
          'amount': amount,
          'paymentDate': _dateFormat.format(paymentDate),
          'notes': notes,
        },
      );
      return Repayment.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteRepayment({required String transactionId, required String repaymentId}) async {
    try {
      await _dio.delete<void>('/transactions/$transactionId/repayments/$repaymentId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
