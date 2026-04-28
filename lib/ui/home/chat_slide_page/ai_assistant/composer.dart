import 'dart:ui' as ui show BoxHeightStyle;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../ai/model/ai_provider_config.dart';
import '../../../../constants/constants.dart';
import '../../../../constants/resources.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../widgets/action_button.dart';
import '../../../../widgets/actions/actions.dart';
import '../../../../widgets/high_light_text.dart';
import '../../../../widgets/menu.dart';
import 'constants.dart';

class AiAssistantComposer extends StatelessWidget {
  const AiAssistantComposer({
    required this.focusNode,
    required this.textEditingController,
    required this.enabled,
    required this.enabledAiProviders,
    required this.requestInFlight,
    required this.onSend,
    required this.onStop,
    required this.onProviderSelected,
    required this.onModelSelected,
    this.provider,
    super.key,
  });

  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final bool enabled;
  final AiProviderConfig? provider;
  final List<AiProviderConfig> enabledAiProviders;
  final bool requestInFlight;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final ValueChanged<AiProviderConfig> onProviderSelected;
  final ValueChanged<String?> onModelSelected;

  @override
  Widget build(BuildContext context) {
    final fieldColor = context.dynamicColor(
      const Color.fromRGBO(245, 247, 250, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: context.theme.primary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider != null) ...[
            _AiAssistantModeBar(
              provider: provider!,
              enabledAiProviders: enabledAiProviders,
              onProviderSelected: onProviderSelected,
              onModelSelected: onModelSelected,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: fieldColor,
                  ),
                  alignment: Alignment.center,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: textEditingController,
                    builder: (context, value, child) {
                      final hasInputText = value.text.trim().isNotEmpty;
                      final canSend =
                          enabled &&
                          !requestInFlight &&
                          hasInputText &&
                          value.composing.composed;

                      return FocusableActionDetector(
                        autofocus: true,
                        shortcuts: {
                          if (canSend)
                            const SingleActivator(LogicalKeyboardKey.enter):
                                const _SendMessageIntent(),
                          const SingleActivator(LogicalKeyboardKey.escape):
                              const EscapeIntent(),
                        },
                        actions: {
                          _SendMessageIntent: CallbackAction<Intent>(
                            onInvoke: (_) {
                              onSend();
                              return null;
                            },
                          ),
                          EscapeIntent: CallbackAction<EscapeIntent>(
                            onInvoke: (_) {
                              focusNode.unfocus();
                              return null;
                            },
                          ),
                        },
                        child: Stack(
                          children: [
                            TextField(
                              focusNode: focusNode,
                              controller: textEditingController,
                              enabled: enabled,
                              minLines: 1,
                              maxLines: 7,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(
                                  kMaxTextLength,
                                ),
                              ],
                              textAlignVertical: TextAlignVertical.center,
                              style: TextStyle(
                                color: context.theme.text,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.only(
                                  left: 10,
                                  right: 10,
                                  top: 8,
                                  bottom: 8,
                                ),
                              ),
                              selectionHeightStyle:
                                  ui.BoxHeightStyle.includeLineSpacingMiddle,
                              contextMenuBuilder: (context, state) =>
                                  MixinAdaptiveSelectionToolbar(
                                    editableTextState: state,
                                  ),
                            ),
                            if (!hasInputText)
                              Positioned.fill(
                                left: 8,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: IgnorePointer(
                                    child: Text(
                                      enabled
                                          ? aiAssistantInputHint
                                          : aiAssistantUnavailable,
                                      style: TextStyle(
                                        color: context.theme.secondaryText,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: textEditingController,
                builder: (context, value, child) {
                  final hasInputText = value.text.trim().isNotEmpty;
                  final interactive =
                      enabled && (requestInFlight || hasInputText);
                  final buttonColor =
                      !enabled || (!requestInFlight && !hasInputText)
                      ? context.theme.secondaryText
                      : requestInFlight
                      ? context.theme.red
                      : context.theme.accent;

                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: interactive ? 1 : 0.45,
                    child: ActionButton(
                      name: requestInFlight
                          ? Resources.assetsImagesRecordStopSvg
                          : Resources.assetsImagesIcSendSvg,
                      color: buttonColor,
                      interactive: interactive,
                      onTap: requestInFlight ? onStop : onSend,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendMessageIntent extends Intent {
  const _SendMessageIntent();
}

class _AiAssistantModeBar extends StatelessWidget {
  const _AiAssistantModeBar({
    required this.provider,
    required this.enabledAiProviders,
    required this.onProviderSelected,
    required this.onModelSelected,
  });

  final AiProviderConfig provider;
  final List<AiProviderConfig> enabledAiProviders;
  final ValueChanged<AiProviderConfig> onProviderSelected;
  final ValueChanged<String?> onModelSelected;

  @override
  Widget build(BuildContext context) {
    final providerOptions = enabledAiProviders
        .map(
          (item) => CustomPopupMenuItem<AiProviderConfig>(
            title: item.name,
            value: item,
          ),
        )
        .toList(growable: false);
    final modelOptions = provider.models
        .where((item) => item.trim().isNotEmpty)
        .map(
          (item) => CustomPopupMenuItem<String>(
            title: item.trim(),
            value: item.trim(),
          ),
        )
        .toList(growable: false);

    return SizedBox(
      width: double.infinity,
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          const dividerSpace = 21.0;
          final availableWidth = constraints.maxWidth - spacing - dividerSpace;

          return Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: availableWidth > 0 ? availableWidth / 2 : 0,
                ),
                child: _AiModeChip<AiProviderConfig>(
                  icon: Icons.hub_rounded,
                  label: provider.name,
                  items: providerOptions,
                  enabled: providerOptions.length > 1,
                  onSelected: onProviderSelected,
                ),
              ),
              const SizedBox(width: 10),
              _AiModeDivider(),
              const SizedBox(width: 10),
              Expanded(
                child: _AiModeChip<String>(
                  icon: Icons.tune_rounded,
                  label: provider.model,
                  items: modelOptions,
                  enabled: modelOptions.length > 1,
                  fill: true,
                  onSelected: onModelSelected,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AiModeDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 14,
    color: context.dynamicColor(
      const Color.fromRGBO(0, 0, 0, 0.08),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.1),
    ),
  );
}

class _AiModeChip<T> extends StatelessWidget {
  const _AiModeChip({
    required this.icon,
    required this.label,
    required this.items,
    required this.onSelected,
    required this.enabled,
    this.fill = false,
  });

  final IconData icon;
  final String label;
  final List<CustomPopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final bool enabled;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.theme.secondaryText),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.theme.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (enabled) ...[
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: context.theme.secondaryText,
          ),
        ],
      ],
    );

    if (!enabled || items.isEmpty) return child;

    return CustomPopupMenuButton<T>(
      itemBuilder: (_) => items,
      onSelected: onSelected,
      color: Colors.transparent,
      useActionButton: false,
      child: child,
    );
  }
}
