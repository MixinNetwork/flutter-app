import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../constants/constants.dart';
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
        appBar: MixinAppBar(
          title: Text(context.l10n.proxy),
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

class _ProxySettingWidget extends HookConsumerWidget {
  const _ProxySettingWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enableProxy = useListenableConverter(
          context.database.settingProperties,
          converter: (settingProperties) => settingProperties.enableProxy,
        ).data ??
        false;
    final hasProxyConfig = useListenableConverter(
          context.database.settingProperties,
          converter: (settingProperties) =>
              settingProperties.proxyList.isNotEmpty,
        ).data ??
        false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CellGroup(
          cellBackgroundColor: context.theme.settingCellBackgroundColor,
          child: CellItem(
            title: Text(context.l10n.proxy),
            trailing: Transform.scale(
                scale: 0.7,
                child: CupertinoSwitch(
                  activeColor: context.theme.accent,
                  value: hasProxyConfig && enableProxy,
                  onChanged: !hasProxyConfig
                      ? null
                      : (bool value) => context
                          .database.settingProperties.enableProxy = value,
                )),
          ),
        ),
        CellGroup(
          cellBackgroundColor: context.theme.settingCellBackgroundColor,
          child: Column(
            children: [
              CellItem(
                title: Text(context.l10n.addProxy),
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

class _ProxyItemList extends HookConsumerWidget {
  const _ProxyItemList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        color: context.theme.settingCellBackgroundColor,
        child: ListTile(
          leading: SizedBox(
            height: double.infinity,
            width: 20,
            child: selected
                ? Icon(
                    Icons.check,
                    color: context.theme.icon,
                    size: 20,
                  )
                : null,
          ),
          minLeadingWidth: 0,
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
            color: context.theme.icon,
            onTap: () {
              context.database.settingProperties.removeProxy(proxy.id);
              if (selected) {
                context.database.settingProperties.selectedProxyId = null;
                context.database.settingProperties.enableProxy = false;
              }
            },
          ),
          onTap: () {
            if (selected) {
              return;
            }
            context.database.settingProperties.selectedProxyId = proxy.id;
          },
        ),
      );
}

class _ProxyAddDialog extends HookConsumerWidget {
  const _ProxyAddDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxyType = useState<ProxyType>(ProxyType.http);
    final proxyHostController = useTextEditingController();
    final proxyPortController = useTextEditingController();
    final proxyUsernameController = useTextEditingController();
    final proxyPasswordController = useTextEditingController();
    return AlertDialogLayout(
      title: Text(context.l10n.addProxy),
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
              context.l10n.proxyType,
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ProxyTypeWidget(proxyType: proxyType),
            const SizedBox(height: 16),
            Text(
              context.l10n.proxyConnection,
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ProxyInputWidget(
              firstController: proxyHostController,
              secondController: proxyPortController,
              firstHintText: context.l10n.host,
              secondHintText: context.l10n.port,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.proxyAuth,
              style: TextStyle(
                color: context.theme.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ProxyInputWidget(
              firstController: proxyUsernameController,
              secondController: proxyPasswordController,
              firstHintText: context.l10n.username,
              secondHintText: context.l10n.password,
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
        borderRadius: const BorderRadius.all(Radius.circular(8)),
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
            inputFormatters: [
              LengthLimitingTextInputFormatter(kDefaultTextInputLimit)
            ],
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
            inputFormatters: [
              LengthLimitingTextInputFormatter(kDefaultTextInputLimit)
            ],
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
