class SubscriptionModel {
  final String requestId;
  final String fullName;
  final String phoneNumber;
  final String deviceId;
  final String appVersion;
  final String status; // 'Pending', 'Available', 'Stopped', 'NotFound'
  final int allowedCards;
  final String limitType; // 'Daily', 'Lifetime'
  final int cardsHuntedToday;
  final int totalCardsHunted;
  final String? lastHuntDate;
  final String? serverTime;
  final String? serverDate;

  // Version Control & Update Enforcement
  final bool isVersionSupported;
  final String serverAppVersion;
  final String minSupportedVersion;
  final bool forceUpdate;
  final String apkDownloadUrl;
  final String updateTitle;
  final String updateNotes;

  const SubscriptionModel({
    required this.requestId,
    required this.fullName,
    required this.phoneNumber,
    required this.deviceId,
    this.appVersion = '',
    required this.status,
    this.allowedCards = 100,
    this.limitType = 'Daily',
    this.cardsHuntedToday = 0,
    this.totalCardsHunted = 0,
    this.lastHuntDate,
    this.serverTime,
    this.serverDate,
    this.isVersionSupported = true,
    this.serverAppVersion = '1.1.0',
    this.minSupportedVersion = '1.1.0',
    this.forceUpdate = true,
    this.apkDownloadUrl = 'https://main.terhabb.com',
    this.updateTitle = 'تحديث إلزامي جديد متوفر',
    this.updateNotes = '',
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
      appVersion: json['app_version']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NotFound',
      allowedCards: (json['allowed_cards'] as num?)?.toInt() ?? 100,
      limitType: json['limit_type']?.toString() ?? 'Daily',
      cardsHuntedToday: (json['cards_hunted_today'] as num?)?.toInt() ?? 0,
      totalCardsHunted: (json['total_cards_hunted'] as num?)?.toInt() ?? 0,
      lastHuntDate: json['last_hunt_date']?.toString(),
      serverTime: json['server_time']?.toString(),
      serverDate: json['server_date']?.toString(),
      isVersionSupported: json['is_version_supported'] != false,
      serverAppVersion: json['server_app_version']?.toString() ?? '1.1.0',
      minSupportedVersion: json['min_supported_version']?.toString() ?? '1.1.0',
      forceUpdate: json['force_update'] != false,
      apkDownloadUrl: json['apk_download_url']?.toString() ?? 'https://main.terhabb.com',
      updateTitle: json['update_title']?.toString() ?? 'تحديث إلزامي جديد متوفر',
      updateNotes: json['update_notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'device_id': deviceId,
      'app_version': appVersion,
      'status': status,
      'allowed_cards': allowedCards,
      'limit_type': limitType,
      'cards_hunted_today': cardsHuntedToday,
      'total_cards_hunted': totalCardsHunted,
      'last_hunt_date': lastHuntDate,
      'server_time': serverTime,
      'server_date': serverDate,
      'is_version_supported': isVersionSupported,
      'server_app_version': serverAppVersion,
      'min_supported_version': minSupportedVersion,
      'force_update': forceUpdate,
      'apk_download_url': apkDownloadUrl,
      'update_title': updateTitle,
      'update_notes': updateNotes,
    };
  }

  SubscriptionModel copyWith({
    String? requestId,
    String? fullName,
    String? phoneNumber,
    String? deviceId,
    String? appVersion,
    String? status,
    int? allowedCards,
    String? limitType,
    int? cardsHuntedToday,
    int? totalCardsHunted,
    String? lastHuntDate,
    String? serverTime,
    String? serverDate,
    bool? isVersionSupported,
    String? serverAppVersion,
    String? minSupportedVersion,
    bool? forceUpdate,
    String? apkDownloadUrl,
    String? updateTitle,
    String? updateNotes,
  }) {
    return SubscriptionModel(
      requestId: requestId ?? this.requestId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      deviceId: deviceId ?? this.deviceId,
      appVersion: appVersion ?? this.appVersion,
      status: status ?? this.status,
      allowedCards: allowedCards ?? this.allowedCards,
      limitType: limitType ?? this.limitType,
      cardsHuntedToday: cardsHuntedToday ?? this.cardsHuntedToday,
      totalCardsHunted: totalCardsHunted ?? this.totalCardsHunted,
      lastHuntDate: lastHuntDate ?? this.lastHuntDate,
      serverTime: serverTime ?? this.serverTime,
      serverDate: serverDate ?? this.serverDate,
      isVersionSupported: isVersionSupported ?? this.isVersionSupported,
      serverAppVersion: serverAppVersion ?? this.serverAppVersion,
      minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
      forceUpdate: forceUpdate ?? this.forceUpdate,
      apkDownloadUrl: apkDownloadUrl ?? this.apkDownloadUrl,
      updateTitle: updateTitle ?? this.updateTitle,
      updateNotes: updateNotes ?? this.updateNotes,
    );
  }
}
