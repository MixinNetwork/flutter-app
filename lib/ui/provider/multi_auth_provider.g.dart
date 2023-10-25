// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multi_auth_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthState _$AuthStateFromJson(Map<String, dynamic> json) => AuthState(
      account: Account.fromJson(json['account'] as Map<String, dynamic>),
      privateKey: json['privateKey'] as String,
    );

Map<String, dynamic> _$AuthStateToJson(AuthState instance) => <String, dynamic>{
      'account': instance.account.toJson(),
      'privateKey': instance.privateKey,
    };

MultiAuthState _$MultiAuthStateFromJson(Map<String, dynamic> json) =>
    MultiAuthState(
      auths: (json['auths'] as List<dynamic>?)
              ?.map((e) => AuthState.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activeUserId: json['activeUserId'] as String?,
    );

Map<String, dynamic> _$MultiAuthStateToJson(MultiAuthState instance) =>
    <String, dynamic>{
      'auths': instance.auths.map((e) => e.toJson()).toList(),
      'activeUserId': instance.activeUserId,
    };
