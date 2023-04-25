import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';

class ProxyPage extends StatelessWidget {
  const ProxyPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.theme.background,
        appBar: const MixinAppBar(
          title: Text('Proxy'),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: SingleChildScrollView(
            child: Column(
              children: const [
                SizedBox(height: 40),
                _ProxySettingWidget(),
              ],
            ),
          ),
        ),
      );
}

class _ProxySettingWidget extends HookWidget {
  const _ProxySettingWidget();

  @override
  Widget build(BuildContext context) {
    final enableProxy = useListenableConverter(
          context.database.settingProperties,
          converter: (settingProperties) => settingProperties.enableProxy,
        ).data ??
        false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 14, top: 10),
          child: Text(
            'Proxy',
            style: TextStyle(
              color: context.theme.secondaryText,
              fontSize: 14,
            ),
          ),
        ),
        CellGroup(
          child: CellItem(
            title: const Text('enable proxy'),
            trailing: Transform.scale(
                scale: 0.7,
                child: CupertinoSwitch(
                  activeColor: context.theme.accent,
                  value: enableProxy,
                  onChanged: (bool value) =>
                      context.database.settingProperties.enableProxy = value,
                )),
          ),
        ),
      ],
    );
  }
}
