import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/logger.dart';
import '../../utils/proxy.dart';
import '../../widgets/action_button.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/cell.dart';
import '../../widgets/dialog.dart';

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
          child: const SingleChildScrollView(
            child: Column(
              children: [
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
        CellGroup(
          child: Column(
            children: [
              CellItem(
                title: const Text('Add Proxy'),
                leading: Icon(
                  Icons.add,
                  color: context.theme.icon,
                ),
                trailing: null,
                onTap: () {
                  showMixinDialog(
                    context: context,
                    child: const _ProxyAddDialog(),
                  );
                },
              ),
              Divider(height: 0.5, indent: 56, color: context.theme.divider),
              const _ProxyItemList(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProxyItemList extends HookWidget {
  const _ProxyItemList();

  @override
  Widget build(BuildContext context) {
    final proxyList = useListenableConverter(
          context.database.settingProperties,
          converter: (settingProperties) => settingProperties.proxyList,
        ).data ??
        const [];
    final selectedProxyId = useListenableConverter(
          context.database.settingProperties,
          converter: (settingProperties) => settingProperties.selectedProxyId,
        ).data ??
        proxyList.firstOrNull?.id;
    return Column(
      children: proxyList
          .map(
            (proxy) => _ProxyItemWidget(
              proxy: proxy,
              selected: selectedProxyId == proxy.id,
            ),
          )
          .toList(),
    );
  }
}

class _ProxyItemWidget extends StatelessWidget {
  const _ProxyItemWidget({
    required this.proxy,
    required this.selected,
  });

  final ProxyConfig proxy;

  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
        color: context.theme.listSelected,
        child: ListTile(
          leading: selected
              ? Icon(
                  Icons.check,
                  color: context.theme.icon,
                  size: 20,
                )
              : const SizedBox.shrink(),
          title: Text(
            '${proxy.host}:${proxy.port}',
            style: TextStyle(
              fontSize: 16,
              color: context.theme.text,
            ),
          ),
          subtitle: Text(
            proxy.type.name,
            style: TextStyle(
              fontSize: 14,
              color: context.theme.secondaryText,
            ),
          ),
          trailing: ActionButton(
            name: Resources.assetsImagesDeleteSvg,
            onTap: () {
              context.database.settingProperties.removeProxy(proxy.id);
              if (selected) {
                context.database.settingProperties.selectedProxyId = null;
              }
            },
          ),
          onTap: () {},
        ),
      );
}

class _ProxyAddDialog extends HookWidget {
  const _ProxyAddDialog();

  @override
  Widget build(BuildContext context) {
    final proxyType = useState<ProxyType>(ProxyType.http);
    final proxyHostController = useTextEditingController();
    final proxyPortController = useTextEditingController();
    final proxyUsernameController = useTextEditingController();
    final proxyPasswordController = useTextEditingController();
    return AlertDialogLayout(
      title: const Text('Add Proxy'),
      titleMarginBottom: 24,
      content: DefaultTextStyle.merge(
        style: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
          color: context.theme.text,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Proxy type',
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ProxyTypeWidget(proxyType: proxyType),
            const SizedBox(height: 16),
            Text(
              'Connection',
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ProxyInputWidget(
              firstController: proxyHostController,
              secondController: proxyPortController,
              firstHintText: 'Host',
              secondHintText: 'Port',
            ),
            const SizedBox(height: 16),
            Text(
              'Authentication (optional)',
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ProxyInputWidget(
              firstController: proxyUsernameController,
              secondController: proxyPasswordController,
              firstHintText: 'Username',
              secondHintText: 'Password',
            ),
          ],
        ),
      ),
      actions: [
        MixinButton(
          backgroundTransparent: true,
          onTap: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        MixinButton(
          onTap: () {
            final proxyHost = proxyHostController.text;
            final proxyPort = int.tryParse(proxyPortController.text);

            if (proxyPort == null) {
              return;
            }
            final id = const Uuid().v4();
            final config = ProxyConfig(
              type: proxyType.value,
              host: proxyHost,
              port: proxyPort,
              id: id,
            );
            i('add proxy config: ${config.type} ${config.host}:${config.port}');
            context.database.settingProperties.addProxy(config);
            Navigator.pop(context);
          },
          child: Text(context.l10n.add),
        ),
      ],
    );
  }
}

class _ProxyTypeWidget extends StatelessWidget {
  const _ProxyTypeWidget({required this.proxyType});

  final ValueNotifier<ProxyType> proxyType;

  @override
  Widget build(BuildContext context) => Material(
        color: context.theme.listSelected,
        borderRadius: BorderRadius.circular(8),
        child: ListTileTheme(
          data: ListTileThemeData(
            dense: true,
            textColor: context.theme.text,
          ),
          child: Column(
            children: [
              ListTile(
                title: const Text('HTTP'),
                trailing: proxyType.value == ProxyType.http
                    ? SvgPicture.asset(
                        Resources.assetsImagesCheckedSvg,
                        width: 24,
                        height: 24,
                      )
                    : null,
                onTap: () => proxyType.value = ProxyType.http,
              ),
              Divider(height: 1, color: context.theme.divider),
              ListTile(
                title: const Text('SOCKS5'),
                trailing: proxyType.value == ProxyType.socks5
                    ? SvgPicture.asset(
                        Resources.assetsImagesCheckedSvg,
                        width: 24,
                        height: 24,
                      )
                    : null,
                onTap: () => proxyType.value = ProxyType.socks5,
              ),
            ],
          ),
        ),
      );
}

class _ProxyInputWidget extends StatelessWidget {
  const _ProxyInputWidget({
    required this.firstController,
    required this.secondController,
    required this.firstHintText,
    required this.secondHintText,
  });

  final TextEditingController firstController;
  final TextEditingController secondController;

  final String firstHintText;
  final String secondHintText;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: firstController,
            style: TextStyle(
              fontSize: 14,
              color: context.theme.text,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: firstHintText,
              hintStyle: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: context.theme.listSelected,
            ),
          ),
          Divider(height: 1, color: context.theme.divider),
          TextField(
            controller: secondController,
            style: TextStyle(
              fontSize: 14,
              color: context.theme.text,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: secondHintText,
              hintStyle: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: context.theme.listSelected,
            ),
          ),
        ],
      );
}
