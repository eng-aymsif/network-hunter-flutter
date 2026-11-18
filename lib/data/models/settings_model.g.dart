// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 1;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      url: fields[0] as String? ?? 'http://a.com',
      loginPath: fields[1] as String? ?? '/login',
      logoutPath: fields[2] as String? ?? '/logout',
      startNumber: fields[3] as String? ?? '',
      maxAttempts: fields[4] as int? ?? 0,
      delayBetween: (fields[5] as num?)?.toDouble() ?? 10.0,
      navTimeout: fields[6] as int? ?? 30000,
      postNavWait: (fields[7] as num?)?.toDouble() ?? 7.0,
      unbanOnError: fields[8] as bool? ?? true,
      unbanMaxRetries: fields[9] as int? ?? 3,
      unbanCooldown: (fields[10] as num?)?.toDouble() ?? 5.0,
      maxConsecutiveErrors: fields[11] as int? ?? 10,
      usernameField: fields[12] as String? ?? 'username',
      passwordField: fields[13] as String? ?? 'password',
      customPassword: fields[14] as String? ?? '',
      useWebView: fields[15] as bool? ?? true,
      injectSaleem: fields[16] as bool? ?? true,
      injectSaveUsername: fields[17] as bool? ?? true,
      usePopupSubmit: fields[18] as bool? ?? true,
      resumeSaved: fields[19] as bool? ?? true,
      skipAlreadyTested: fields[20] as bool? ?? false,
      autoLoginWithHuntedCards: fields[21] as bool? ?? false,
      autoLoginCheckInterval: fields[22] as int? ?? 15,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.loginPath)
      ..writeByte(2)
      ..write(obj.logoutPath)
      ..writeByte(3)
      ..write(obj.startNumber)
      ..writeByte(4)
      ..write(obj.maxAttempts)
      ..writeByte(5)
      ..write(obj.delayBetween)
      ..writeByte(6)
      ..write(obj.navTimeout)
      ..writeByte(7)
      ..write(obj.postNavWait)
      ..writeByte(8)
      ..write(obj.unbanOnError)
      ..writeByte(9)
      ..write(obj.unbanMaxRetries)
      ..writeByte(10)
      ..write(obj.unbanCooldown)
      ..writeByte(11)
      ..write(obj.maxConsecutiveErrors)
      ..writeByte(12)
      ..write(obj.usernameField)
      ..writeByte(13)
      ..write(obj.passwordField)
      ..writeByte(14)
      ..write(obj.customPassword)
      ..writeByte(15)
      ..write(obj.useWebView)
      ..writeByte(16)
      ..write(obj.injectSaleem)
      ..writeByte(17)
      ..write(obj.injectSaveUsername)
      ..writeByte(18)
      ..write(obj.usePopupSubmit)
      ..writeByte(19)
      ..write(obj.resumeSaved)
      ..writeByte(20)
      ..write(obj.skipAlreadyTested)
      ..writeByte(21)
      ..write(obj.autoLoginWithHuntedCards)
      ..writeByte(22)
      ..write(obj.autoLoginCheckInterval);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
