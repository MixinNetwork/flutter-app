import 'package:flutter_app/ui/provider/major_navigation_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('setting navigation keeps one setting destination in the stack', () {
    final notifier = MajorNavigationNotifier()
      ..openSetting(MajorNavigationDestination.editProfilePage)
      ..openSetting(MajorNavigationDestination.aboutPage);

    expect(notifier.state.entries, [
      const MajorNavigationEntry(MajorNavigationDestination.aboutPage),
    ]);
  });

  test('syncing setting category clears route-mode pages', () async {
    final notifier = MajorNavigationNotifier()
      ..open(MajorNavigationDestination.chatPage)
      ..updateRouteMode(true);
    await Future<void>.delayed(Duration.zero);

    final opened = notifier.syncSettingCategory(true);

    expect(opened, isFalse);
    expect(notifier.state.entries, isEmpty);
  });
}
