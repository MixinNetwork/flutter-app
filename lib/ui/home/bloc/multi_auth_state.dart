// ignore_for_file: invalid_use_of_visible_for_testing_member
part of 'multi_auth_cubit.dart';

class MultiAuthState extends Equatable {
  const MultiAuthState({
    Set<AuthState> auths = const {},
  }) : _auths = auths;

  factory MultiAuthState.fromMap(Map<String, dynamic> map) {
    final list = map['auths'] as Iterable<dynamic>?;
    return MultiAuthState(
      auths: list
              ?.map((e) => AuthState.fromMap(e as Map<String, dynamic>))
              .toSet() ??
          {},
    );
  }

  factory MultiAuthState.fromJson(String source) =>
      MultiAuthState.fromMap(json.decode(source) as Map<String, dynamic>);

  final Set<AuthState> _auths;

  AuthState? get current => _auths.isNotEmpty ? _auths.last : null;

  AuthState? get currentAuthState => current;

  Account? get currentUser => currentAuthState?.account;

  String? get currentUserId => currentUser?.userId;

  String? get currentIdentityNumber => currentUser?.identityNumber;

  @override
  List<Object> get props => [
        _auths,
      ];

  Map<String, dynamic> toMap() => {
        'auths': _auths.map((x) => x.toMap()).toList(),
      };

  String toJson() => json.encode(toMap());
}

class AuthState extends Equatable {
  const AuthState({
    required this.account,
    required this.privateKey,

    // Use SettingState instead
    this.messagePreview,
    this.photoAutoDownload,
    this.videoAutoDownload,
    this.fileAutoDownload,
    this.collapsedSidebar,
  });

  factory AuthState.fromMap(Map<String, dynamic> map) => AuthState(
        account: Account.fromJson(map['account'] as Map<String, dynamic>),
        privateKey: map['privateKey'] as String,
        messagePreview: map['messagePreview'] as bool?,
        photoAutoDownload: map['photoAutoDownload'] as bool?,
        videoAutoDownload: map['videoAutoDownload'] as bool?,
        fileAutoDownload: map['fileAutoDownload'] as bool?,
        collapsedSidebar: map['collapsedSidebar'] as bool?,
      );

  factory AuthState.fromJson(String source) =>
      AuthState.fromMap(json.decode(source) as Map<String, dynamic>);

  final Account account;
  final String privateKey;

  // Use SettingState instead
  final bool? messagePreview;
  final bool? photoAutoDownload;
  final bool? videoAutoDownload;
  final bool? fileAutoDownload;
  final bool? collapsedSidebar;

  @override
  List<Object?> get props => [
        account,
        privateKey,
        messagePreview,
        photoAutoDownload,
        videoAutoDownload,
        fileAutoDownload,
        collapsedSidebar,
      ];

  AuthState copyWith({
    Account? account,
    String? privateKey,
    bool? messagePreview,
    bool? photoAutoDownload,
    bool? videoAutoDownload,
    bool? fileAutoDownload,
    bool? collapsedSidebar,
  }) =>
      AuthState(
        account: account ?? this.account,
        privateKey: privateKey ?? this.privateKey,
        messagePreview: messagePreview ?? this.messagePreview,
        photoAutoDownload: photoAutoDownload ?? this.photoAutoDownload,
        videoAutoDownload: videoAutoDownload ?? this.videoAutoDownload,
        fileAutoDownload: fileAutoDownload ?? this.fileAutoDownload,
        collapsedSidebar: collapsedSidebar ?? this.collapsedSidebar,
      );

  Map<String, dynamic> toMap() => {
        'account': account.toJson(),
        'privateKey': privateKey,
        'messagePreview': messagePreview,
        'photoAutoDownload': photoAutoDownload,
        'videoAutoDownload': videoAutoDownload,
        'fileAutoDownload': fileAutoDownload,
        'collapsedSidebar': collapsedSidebar,
      };

  String toJson() => json.encode(toMap());
}
