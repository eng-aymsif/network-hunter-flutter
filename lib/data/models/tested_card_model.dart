import 'package:hive/hive.dart';

part 'tested_card_model.g.dart';

@HiveType(typeId: 2)
class TestedCardModel {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String cardNumber;

  @HiveField(2)
  final String testedAt;

  @HiveField(3)
  final String status; // 'success' or 'failed'

  @HiveField(4)
  final String portalMessage;

  @HiveField(5)
  final bool isLastTested;

  TestedCardModel({
    this.id,
    required this.cardNumber,
    required this.testedAt,
    required this.status,
    required this.portalMessage,
    this.isLastTested = false,
  });

  bool get isSuccess => status.toLowerCase() == 'success';

  TestedCardModel copyWith({
    int? id,
    String? cardNumber,
    String? testedAt,
    String? status,
    String? portalMessage,
    bool? isLastTested,
  }) {
    return TestedCardModel(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      testedAt: testedAt ?? this.testedAt,
      status: status ?? this.status,
      portalMessage: portalMessage ?? this.portalMessage,
      isLastTested: isLastTested ?? this.isLastTested,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'card_number': cardNumber,
      'tested_at': testedAt,
      'status': status,
      'portal_message': portalMessage,
      'is_last_tested': isLastTested ? 1 : 0,
    };
  }

  factory TestedCardModel.fromMap(Map<String, dynamic> map) {
    return TestedCardModel(
      id: map['id'] as int?,
      cardNumber: map['card_number'] as String? ?? '',
      testedAt: map['tested_at'] as String? ?? '',
      status: map['status'] as String? ?? 'failed',
      portalMessage: map['portal_message'] as String? ?? '',
      isLastTested: (map['is_last_tested'] as int? ?? 0) == 1,
    );
  }
}
