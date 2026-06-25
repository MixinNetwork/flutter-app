import 'package:flutter_app/ui/home/desktop_shell_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesktopShellLayout', () {
    test('uses the full rail when the shell has enough width', () {
      final layout = DesktopShellLayout.resolve(
        maxWidth: 900,
        userCollapse: false,
        isPhone: false,
      );

      expect(layout.mode, DesktopShellLayoutMode.fullRail);
      expect(layout.slideWidth, kSlidePageMaxWidth);
      expect(layout.showCollapseControl, isTrue);
      expect(layout.hasDrawer, isFalse);
    });

    test('auto collapses the rail before switching to drawer mode', () {
      final layout = DesktopShellLayout.resolve(
        maxWidth: kResponsiveNavigationMinWidth + 120,
        userCollapse: false,
        isPhone: false,
      );

      expect(layout.mode, DesktopShellLayoutMode.compactRail);
      expect(layout.slideWidth, kSlidePageMinWidth);
      expect(layout.showCollapseControl, isFalse);
    });

    test('uses drawer mode on phone and at the minimum rail width', () {
      final narrow = DesktopShellLayout.resolve(
        maxWidth: kResponsiveNavigationMinWidth,
        userCollapse: false,
        isPhone: false,
      );
      final phone = DesktopShellLayout.resolve(
        maxWidth: 900,
        userCollapse: false,
        isPhone: true,
      );

      expect(narrow.mode, DesktopShellLayoutMode.drawer);
      expect(narrow.slideWidth, 0);
      expect(phone.mode, DesktopShellLayoutMode.drawer);
      expect(phone.slideWidth, 0);
    });

    test('keeps route and media sizing policy in one place', () {
      expect(
        DesktopShellLayout.useMainRouteMode(
          DesktopShellLayout.mainRouteSwitchWidth - 1,
        ),
        isTrue,
      );
      expect(
        DesktopShellLayout.useChatSideRouteMode(
          DesktopShellLayout.chatSideRouteSwitchWidth,
        ),
        isFalse,
      );
      expect(
        DesktopShellLayout.chatSideMediaPageSize(
          maxHeight: 450,
          routeMode: false,
        ),
        30,
      );
      expect(
        DesktopShellLayout.chatSideMediaPageSize(
          maxHeight: 450,
          routeMode: true,
        ),
        40,
      );
    });
  });
}
