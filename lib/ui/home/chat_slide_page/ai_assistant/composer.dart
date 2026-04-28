import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../ai/model/ai_provider_config.dart';
import '../../../../constants/constants.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../widgets/action_button.dart';
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
    final buttonColor = !enabled
        ? context.theme.secondaryText
        : requestInFlight
        ? context.theme.red
        : context.theme.accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: context.theme.primary,
        border: Border(top: BorderSide(color: context.theme.divider)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          color: context.dynamicColor(
            const Color.fromRGBO(245, 247, 250, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider != null) ...[
                _AiAssistantModeBar(
                  provider: provider!,
                  enabledAiProviders: enabledAiProviders,
                  onProviderSelected: onProviderSelected,
                  onModelSelected: onModelSelected,
                ),
                const SizedBox(height: 2),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: focusNode,
                      controller: textEditingController,
                      enabled: enabled,
                      minLines: 1,
                      maxLines: 6,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(kMaxTextLength),
                      ],
                      style: TextStyle(
                        color: context.theme.text,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: enabled
                            ? aiAssistantInputHint
                            : aiAssistantUnavailable,
                        hintStyle: TextStyle(
                          color: context.theme.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionButton(
                    padding: const EdgeInsets.all(6),
                    size: 20,
                    interactive: enabled,
                    onTap: requestInFlight ? onStop : onSend,
                    child: Icon(
                      requestInFlight
                          ? Icons.stop_rounded
                          : Icons.arrow_upward_rounded,
                      size: 18,
                      color: buttonColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.dynamicColor(
              const Color.fromRGBO(0, 0, 0, 0.05),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Flexible(
              child: _AiModeChip<AiProviderConfig>(
                icon: Icons.hub_rounded,
                label: provider.name,
                items: providerOptions,
                enabled: providerOptions.length > 1,
                onSelected: onProviderSelected,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _AiModeChip<String>(
                icon: Icons.tune_rounded,
                label: provider.model,
                items: modelOptions,
                enabled: modelOptions.length > 1,
                onSelected: onModelSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiModeChip<T> extends StatelessWidget {
  const _AiModeChip({
    required this.icon,
    required this.label,
    required this.items,
    required this.onSelected,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final List<CustomPopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      children: [
        Icon(icon, size: 13, color: context.theme.secondaryText),
        const SizedBox(width: 6),
        Expanded(
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
