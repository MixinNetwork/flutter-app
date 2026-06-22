import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/rivepod.dart';

enum MajorNavigationDestination {
  chatPage,
  editProfilePage,
  accountPage,
  accountDeletePage,
  notificationPage,
  chatBackupPage,
  dataAndStorageUsagePage,
  appearancePage,
  aboutPage,
  storageUsage,
  storageUsageDetail,
  proxyPage,
  securityPage,
}

class MajorNavigationEntry extends Equatable {
  const MajorNavigationEntry(this.destination, {this.arguments});

  final MajorNavigationDestination destination;
  final Object? arguments;

  @override
  List<Object?> get props => [destination, arguments];
}

class MajorNavigationState extends Equatable {
  const MajorNavigationState({
    this.entries = const [],
  });

  final List<MajorNavigationEntry> entries;

  bool contains(MajorNavigationDestination destination) =>
      entries.any((entry) => entry.destination == destination);

  MajorNavigationState copyWith({
    List<MajorNavigationEntry>? entries,
  }) => MajorNavigationState(
    entries: entries ?? this.entries,
  );

  @override
  List<Object?> get props => [entries];
}

class MajorNavigationNotifier
    extends DistinctStateNotifier<MajorNavigationState> {
  MajorNavigationNotifier() : super(const MajorNavigationState());

  static const settingDestinations = {
    MajorNavigationDestination.editProfilePage,
    MajorNavigationDestination.notificationPage,
    MajorNavigationDestination.chatBackupPage,
    MajorNavigationDestination.dataAndStorageUsagePage,
    MajorNavigationDestination.appearancePage,
    MajorNavigationDestination.aboutPage,
    MajorNavigationDestination.storageUsage,
    MajorNavigationDestination.storageUsageDetail,
    MajorNavigationDestination.accountPage,
    MajorNavigationDestination.accountDeletePage,
    MajorNavigationDestination.proxyPage,
    MajorNavigationDestination.securityPage,
  };

  void clear() {
    state = state.copyWith(entries: []);
  }

  void openChatPage() {
    open(MajorNavigationDestination.chatPage);
  }

  bool syncSettingCategory(bool isSetting, {required bool routeMode}) {
    final openSettingPage = isSetting && !routeMode;
    _removeWhere((entry) {
      if (routeMode) return true;
      return settingDestinations.contains(entry.destination);
    });
    if (openSettingPage) {
      open(settingDestinations.first);
    }
    return openSettingPage;
  }

  void openSetting(MajorNavigationDestination destination) {
    _removeWhere((entry) => settingDestinations.contains(entry.destination));
    open(destination);
  }

  void open(MajorNavigationDestination destination, {Object? arguments}) {
    final entry = MajorNavigationEntry(destination, arguments: arguments);
    final entries = state.entries.toList();
    final index = entries.indexWhere(
      (item) => item.destination == destination,
    );
    if (entries.isNotEmpty && index == entries.length - 1) return;
    if (index != -1) entries.removeRange(index, entries.length);
    state = state.copyWith(entries: [...entries, entry]);
  }

  void _removeWhere(bool Function(MajorNavigationEntry entry) test) {
    state = state.copyWith(entries: state.entries.toList()..removeWhere(test));
  }
}

final majorNavigationProvider =
    StateNotifierProvider.autoDispose<
      MajorNavigationNotifier,
      MajorNavigationState
    >((ref) => MajorNavigationNotifier());
