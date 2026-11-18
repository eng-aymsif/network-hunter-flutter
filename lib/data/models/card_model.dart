import 'package:hive/hive.dart';

part 'card_model.g.dart';

@HiveType(typeId: 0)
class CardModel {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String cardNumber;

  @HiveField(2)
  final String foundAt;

  @HiveField(3)
  final bool isUsed;

  @HiveField(4)
  final String loginUrl;

  @HiveField(5)
  final String notes;

  @HiveField(6)
  final int priorityOrder;

  CardModel({
    this.id,
    required this.cardNumber,
    required this.loginUrl,
    required this.foundAt,
    this.isUsed = false,
    this.notes = '',
    this.priorityOrder = 0,
  });

  CardModel copyWith({
    int? id,
    String? cardNumber,
    String? loginUrl,
    String? foundAt,
    bool? isUsed,
    String? notes,
    int? priorityOrder,
  }) {
    return CardModel(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      loginUrl: loginUrl ?? this.loginUrl,
      foundAt: foundAt ?? this.foundAt,
      isUsed: isUsed ?? this.isUsed,
      notes: notes ?? this.notes,
      priorityOrder: priorityOrder ?? this.priorityOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'card_number': cardNumber,
      'login_url': loginUrl,
      'found_at': foundAt,
      'is_used': isUsed ? 1 : 0,
      'notes': notes,
      'priority_order': priorityOrder,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] as int?,
      cardNumber: map['card_number'] as String? ?? '',
      loginUrl: map['login_url'] as String? ?? '',
      foundAt: map['found_at'] as String? ?? '',
      isUsed: (map['is_used'] as int? ?? 0) == 1,
      notes: map['notes'] as String? ?? '',
      priorityOrder: (map['priority_order'] as num?)?.toInt() ?? 0,
    );
  }
}
