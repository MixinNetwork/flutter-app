import 'package:desktop_lifecycle/desktop_lifecycle.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DesktopLifecycleAutoFocus extends HookWidget {
  const DesktopLifecycleAutoFocus({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ref = useRef<FocusNode?>(null);
    useEffect(() {
      void onListen() {
        if (DesktopLifecycle.instance.isActive.value) {
          ref.value?.requestFocus();
          ref.value = null;
          return;
        }
        ref.value = FocusManager.instance.primaryFocus;
        ref.value?.unfocus();
      }

      DesktopLifecycle.instance.isActive.addListener(onListen);
      return () {
        DesktopLifecycle.instance.isActive.removeListener(onListen);
      };
    });

    return child;
  }
}
