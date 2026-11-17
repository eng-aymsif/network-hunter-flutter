class SubscriptionModel {
  final String requestId;
  final String fullName;
  final String phoneNumber;
  final String deviceId;
  final String status; // 'Pending', 'Available', 'Stopped', 'NotFound'
  final int allowedCards;
  final String limitType; // 'Daily', 'Lifetime'
  final int cardsHuntedToday;
  final int totalCardsHunted;
  final String? lastHuntDate;
  final String? serverTime;
  final String? serverDate;

  const SubscriptionModel({
    required this.requestId,
    required this.fullName,
    required this.phoneNumber,
    required this.deviceId,
    required this.status,
    this.allowedCards = 100,
    this.limitType = 'Daily',
    this.cardsHuntedToday = 0,
    this.totalCardsHunted = 0,
    this.lastHuntDate,
    this.serverTime,
    this.serverDate,
  });

  bool get isAvailable => status == 'Available';
  bool get isPending => status == 'Pending';
  bool get isStopped => status == 'Stopped';
  bool get isNotFound => status == 'NotFound';
  bool get isDaily => limitType == 'Daily';

  int get remainingCards {
    final current = isDaily ? cardsHuntedToday : totalCardsHunted;
    final left = allowedCards - current;
    return left > 0 ? left : 0;
  }

  bool get isQuotaExhausted => remainingCards <= 0;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      requestId: json['request_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      deviceId: json['device_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NotFound',
      allowedCards: (json['allowed_cards'] as num?)?.toInt() ?? 100,
      limitType: json['limit_type']?.toString() ?? 'Daily',
      cardsHuntedToday: (json['cards_hunted_today'] as num?)?.toInt() ?? 0,
      totalCardsHunted: (json['total_cards_hunted'] as num?)?.toInt() ?? 0,
      lastHuntDate: json['last_hunt_date']?.toString(),
      serverTime: json['server_time']?.toString(),
      serverDate: json['server_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'device_id': deviceId,
      'status': status,
      'allowed_cards': allowedCards,
      'limit_type': limitType,
      'cards_hunted_today': cardsHuntedToday,
      'total_cards_hunted': totalCardsHunted,
      'last_hunt_date': lastHuntDate,
      'server_time': serverTime,
      'server_date': serverDate,
    };
  }

  SubscriptionModel copyWith({
    String? requestId,
    String? fullName,
    String? phoneNumber,
    String? deviceId,
    String? status,
    int? allowedCards,
    String? limitType,
    int? cardsHuntedToday,
    int? totalCardsHunted,
    String? lastHuntDate,
    String? serverTime,
    String? serverDate,
  }) {
    return SubscriptionModel(
      requestId: requestId ?? this.requestId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      deviceId: deviceId ?? this.deviceId,
      status: status ?? this.status,
      allowedCards: allowedCards ?? this.allowedCards,
      limitType: limitType ?? this.limitType,
      cardsHuntedToday: cardsHuntedToday ?? this.cardsHuntedToday,
      totalCardsHunted: totalCardsHunted ?? this.totalCardsHunted,
      lastHuntDate: lastHuntDate ?? this.lastHuntDate,
      serverTime: serverTime ?? this.serverTime,
      serverDate: serverDate ?? this.serverDate,
    );
  }
}
