part of 'multi_auth_cubit.dart';

class MultiAuthState extends Equatable {
  const MultiAuthState({
    this.auths = const {},
  });

  factory MultiAuthState.fromMap(Map<String, dynamic> map) => MultiAuthState(
        auths:
            // ignore: avoid_dynamic_calls
            Set<AuthState>.from(map['auths']?.map((x) => AuthState.fromMap(x))),
      );

  factory MultiAuthState.fromJson(String source) =>
      MultiAuthState.fromMap(json.decode(source));

  final Set<AuthState> auths;

  AuthState? get current => auths.isNotEmpty ? auths.last : null;

  bool get currentMessagePreview => current?.messagePreview ?? true;

  bool get currentPhotoAutoDownload => current?.photoAutoDownload ?? true;

  bool get currentVideoAutoDownload => current?.videoAutoDownload ?? true;

  bool get currentFileAutoDownload => current?.fileAutoDownload ?? true;

  @override
  List<Object> get props => [
        auths,
      ];

  Map<String, dynamic> toMap() {
    return {
      'auths': auths.map((x) => x.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());
}

class AuthState extends Equatable {
  const AuthState({
    required this.account,
    required this.privateKey,
    this.messagePreview,
    this.photoAutoDownload,
    this.videoAutoDownload,
    this.fileAutoDownload,
  });

  factory AuthState.fromMap(Map<String, dynamic> map) => AuthState(
        account: Account.fromJson(map['account']),
        privateKey: map['privateKey'],
        messagePreview: map['messagePreview'],
        photoAutoDownload: map['photoAutoDownload'],
        videoAutoDownload: map['videoAutoDownload'],
        fileAutoDownload: map['fileAutoDownload'],
      );

  factory AuthState.fromJson(String source) =>
      AuthState.fromMap(json.decode(source));

  final Account account;
  final String privateKey;
  final bool? messagePreview;
  final bool? photoAutoDownload;
  final bool? videoAutoDownload;
  final bool? fileAutoDownload;

  @override
  List<Object?> get props => [
        account,
        privateKey,
        messagePreview,
        photoAutoDownload,
        videoAutoDownload,
        fileAutoDownload,
      ];

  AuthState copyWith({
    Account? account,
    String? privateKey,
    bool? messagePreview,
    bool? photoAutoDownload,
    bool? videoAutoDownload,
    bool? fileAutoDownload,
  }) {
    return AuthState(
      account: account ?? this.account,
      privateKey: privateKey ?? this.privateKey,
      messagePreview: messagePreview ?? this.messagePreview,
      photoAutoDownload: photoAutoDownload ?? this.photoAutoDownload,
      videoAutoDownload: videoAutoDownload ?? this.videoAutoDownload,
      fileAutoDownload: fileAutoDownload ?? this.fileAutoDownload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account': account.toJson(),
      'privateKey': privateKey,
      'messagePreview': messagePreview,
      'photoAutoDownload': photoAutoDownload,
      'videoAutoDownload': videoAutoDownload,
      'fileAutoDownload': fileAutoDownload,
    };
  }

  String toJson() => json.encode(toMap());
}
