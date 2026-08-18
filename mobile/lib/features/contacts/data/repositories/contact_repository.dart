import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/contact.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(ref.watch(dioProvider));
});

class ContactRepository {
  ContactRepository(this._dio);

  final Dio _dio;

  Future<List<Contact>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>('/contacts');
      return response.data!.map((e) => Contact.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Contact> get(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/contacts/$id');
      return Contact.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Contact> create({required String name, String? phone, String? email, String? notes}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/contacts',
        data: {'name': name, 'phone': phone, 'email': email, 'notes': notes},
      );
      return Contact.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Contact> update({
    required String id,
    required String name,
    String? phone,
    String? email,
    String? notes,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/contacts/$id',
        data: {'name': name, 'phone': phone, 'email': email, 'notes': notes},
      );
      return Contact.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/contacts/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
