class CardModel {
  final int? id;
  final String cardNumber;
  final String loginUrl;
  final String foundAt;
  final bool isUsed;
  final String notes;

  CardModel({
    this.id,
    required this.cardNumber,
    required this.loginUrl,
    required this.foundAt,
    this.isUsed = false,
    this.notes = '',
  });

  CardModel copyWith({
    int? id,
    String? cardNumber,
    String? loginUrl,
    String? foundAt,
    bool? isUsed,
    String? notes,
  }) {
    return CardModel(
      id: id ?? this.id,
      cardNumber: cardNumber ?? this.cardNumber,
      loginUrl: loginUrl ?? this.loginUrl,
      foundAt: foundAt ?? this.foundAt,
      isUsed: isUsed ?? this.isUsed,
      notes: notes ?? this.notes,
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
    );
  }
}
