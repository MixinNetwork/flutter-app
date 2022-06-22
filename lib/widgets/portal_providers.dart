import 'package:flutter/widgets.dart';
import 'package:flutter_portal/flutter_portal.dart';

const secondPortal = PortalLabel('second');

class PortalProviders extends StatelessWidget {
  const PortalProviders({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) => Portal(
        labels: const [secondPortal],
        child: Portal(
          child: child,
        ),
      );
}
