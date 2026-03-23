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
import '../../widgets/high_light_text.dart';
import '../provider/database_provider.dart';
import '../provider/ui_context_providers.dart';

class ProxyPage extends ConsumerWidget {
  const ProxyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    return Scaffold(
      backgroundColor: theme.background,
      appBar: MixinAppBar(title: Text(l10n.proxy)),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: const SingleChildScrollView(
          child: Column(
            children: [SizedBox(height: 40), _ProxySettingWidget()],
          ),
        ),
      ),
    );
  }
}

class _ProxySettingWidget extends HookConsumerWidget {
  const _ProxySettingWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final settingProperties = ref
        .read(databaseProvider)
        .requireValue
        .settingProperties;
    final enableProxy =
        useListenableConverter(
          settingProperties,
          converter: (settingProperties) => settingProperties.enableProxy,
        ).data ??
        false;
    final hasProxyConfig =
        useListenableConverter(
          settingProperties,
          converter: (settingProperties) =>
              settingProperties.proxyList.isNotEmpty,
        ).data ??
        false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CellGroup(
          cellBackgroundColor: theme.settingCellBackgroundColor,
          child: CellItem(
            title: Text(l10n.proxy),
            trailing: Transform.scale(
              scale: 0.7,
              child: CupertinoSwitch(
                activeTrackColor: theme.accent,
                value: hasProxyConfig && enableProxy,
                onChanged: !hasProxyConfig
                    ? null
                    : (value) => settingProperties.enableProxy = value,
              ),
            ),
          ),
        ),
        CellGroup(
          cellBackgroundColor: theme.settingCellBackgroundColor,
          child: Column(
            children: [
              CellItem(
                title: Text(l10n.addProxy),
                leading: Icon(Icons.add, color: theme.icon),
                trailing: null,
                onTap: () {
                  showMixinDialog(
                    context: context,
                    child: const _ProxyAddDialog(),
                  );
                },
              ),
              Divider(
                height: 0.5,
                indent: 56,
                color: theme.divider,
              ),
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
    final settingProperties = ref
        .read(databaseProvider)
        .requireValue
        .settingProperties;
    final proxyList =
        useListenableConverter(
          settingProperties,
          converter: (settingProperties) => settingProperties.proxyList,
        ).data ??
        const [];
    final selectedProxyId =
        useListenableConverter(
          settingProperties,
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

class _ProxyItemWidget extends ConsumerWidget {
  const _ProxyItemWidget({required this.proxy, required this.selected});

  final ProxyConfig proxy;

  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final settingProperties = ref
        .read(databaseProvider)
        .requireValue
        .settingProperties;
    return Material(
      color: theme.settingCellBackgroundColor,
      child: ListTile(
        leading: SizedBox(
          height: double.infinity,
          width: 20,
          child: selected
              ? Icon(
                  Icons.check,
                  color: theme.icon,
                  size: 20,
                )
              : null,
        ),
        minLeadingWidth: 0,
        title: Text(
          '${proxy.host}:${proxy.port}',
          style: TextStyle(fontSize: 16, color: theme.text),
        ),
        subtitle: Text(
          proxy.type.name,
          style: TextStyle(fontSize: 14, color: theme.secondaryText),
        ),
        trailing: ActionButton(
          name: Resources.assetsImagesDeleteSvg,
          color: theme.icon,
          onTap: () {
            settingProperties.removeProxy(proxy.id);
            if (selected) {
              settingProperties.selectedProxyId = null;
              settingProperties.enableProxy = false;
            }
          },
        ),
        onTap: () {
          if (selected) {
            return;
          }
          settingProperties.selectedProxyId = proxy.id;
        },
      ),
    );
  }
}

class _ProxyAddDialog extends HookConsumerWidget {
  const _ProxyAddDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final settingProperties = ref
        .read(databaseProvider)
        .requireValue
        .settingProperties;
    final proxyType = useState<ProxyType>(ProxyType.http);
    final proxyHostController = useTextEditingController();
    final proxyPortController = useTextEditingController();
    final proxyUsernameController = useTextEditingController();
    final proxyPasswordController = useTextEditingController();
    return AlertDialogLayout(
      title: Text(l10n.addProxy),
      titleMarginBottom: 24,
      content: DefaultTextStyle.merge(
        style: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
          color: theme.text,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.proxyType,
              style: TextStyle(
                color: theme.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ProxyTypeWidget(proxyType: proxyType),
            const SizedBox(height: 16),
            Text(
              l10n.proxyConnection,
              style: TextStyle(
                color: theme.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ProxyInputWidget(
              firstController: proxyHostController,
              secondController: proxyPortController,
              firstHintText: l10n.host,
              secondHintText: l10n.port,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.proxyAuth,
              style: TextStyle(
                color: theme.secondaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _ProxyInputWidget(
              firstController: proxyUsernameController,
              secondController: proxyPasswordController,
              firstHintText: l10n.username,
              secondHintText: l10n.password,
            ),
          ],
        ),
      ),
      actions: [
        MixinButton(
          backgroundTransparent: true,
          onTap: () => Navigator.pop(context),
          child: Text(l10n.cancel),
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
            settingProperties.addProxy(config);
            Navigator.pop(context);
          },
          child: Text(l10n.add),
        ),
      ],
    );
  }
}

class _ProxyTypeWidget extends ConsumerWidget {
  const _ProxyTypeWidget({required this.proxyType});

  final ValueNotifier<ProxyType> proxyType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Material(
      color: theme.listSelected,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: ListTileTheme(
        data: ListTileThemeData(dense: true, textColor: theme.text),
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
}

class _ProxyInputWidget extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: firstController,
          style: TextStyle(fontSize: 14, color: theme.text),
          inputFormatters: [
            LengthLimitingTextInputFormatter(kDefaultTextInputLimit),
          ],
          decoration: InputDecoration(
            isDense: true,
            hintText: firstHintText,
            hintStyle: TextStyle(color: theme.secondaryText, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.listSelected,
          ),
          contextMenuBuilder: (context, state) =>
              MixinAdaptiveSelectionToolbar(editableTextState: state),
        ),
        Divider(height: 1, color: theme.divider),
        TextField(
          controller: secondController,
          style: TextStyle(fontSize: 14, color: theme.text),
          inputFormatters: [
            LengthLimitingTextInputFormatter(kDefaultTextInputLimit),
          ],
          decoration: InputDecoration(
            isDense: true,
            hintText: secondHintText,
            hintStyle: TextStyle(color: theme.secondaryText, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.listSelected,
          ),
          contextMenuBuilder: (context, state) =>
              MixinAdaptiveSelectionToolbar(editableTextState: state),
        ),
      ],
    );
  }
}
