import '../../../../core/utils/money.dart';

class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.notes,
    required this.totalOwedToMe,
    required this.totalIOwe,
    required this.netBalance,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      totalOwedToMe: parseAmount(json['totalOwedToMe']),
      totalIOwe: parseAmount(json['totalIOwe']),
      netBalance: parseAmount(json['netBalance']),
    );
  }

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? notes;
  final num totalOwedToMe;
  final num totalIOwe;
  final num netBalance;
}
