class TestedCardModel {
  final int? id;
  final String cardNumber;
  final String testedAt;
  final String status; // 'success' or 'failed'
  final String portalMessage;
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
