import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset;
import 'package:flutter_app/db/extension/conversation.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/mention_cubit.dart';
import 'package:flutter_app/utils/reg_exp_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import 'avatar_view/avatar_view.dart';
import 'brightness_observer.dart';
import 'high_light_text.dart';
import 'interacter_decorated_box.dart';

class MentionPanelPortalEntry extends StatelessWidget {
  const MentionPanelPortalEntry({
    Key key,
    @required this.constraints,
    @required this.child,
  }) : super(key: key);

  final BoxConstraints constraints;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocConverter<MentionCubit, Tuple2<String, List<User>>, bool>(
        converter: (state) => state.item2.isNotEmpty,
        builder: (context, visible) => PortalEntry(
          visible: visible &&
              BlocProvider.of<ConversationCubit>(context)
                      .state
                      ?.isGroupConversation ==
                  true,
          childAnchor: Alignment.topCenter,
          portalAnchor: Alignment.bottomCenter,
          closeDuration: const Duration(milliseconds: 150),
          portal: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 168,
              minWidth: constraints.maxWidth,
              maxWidth: constraints.maxWidth,
            ),
            child: ClipRRect(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                tween: Tween(begin: 0, end: visible ? 1 : 0),
                builder: (context, progress, child) => FractionalTranslation(
                  translation: Offset(0, 1 - progress),
                  child: child,
                ),
                child: _MentionPanel(
                  mentionCubit: BlocProvider.of<MentionCubit>(context),
                  onSelect: (User user) {
                    final textEditingController =
                        context.read<TextEditingController>();
                    textEditingController
                      ..text = textEditingController.text.replaceFirst(
                          mentionRegExp, '@${user.identityNumber} ')
                      ..selection = TextSelection.fromPosition(
                        TextPosition(
                          offset: textEditingController.text.length,
                        ),
                      );
                  },
                ),
              ),
            ),
          ),
          child: child,
        ),
      );
}

class _MentionPanel extends StatelessWidget {
  const _MentionPanel({
    Key key,
    @required this.mentionCubit,
    @required this.onSelect,
  }) : super(key: key);

  final MentionCubit mentionCubit;
  final Function(User user) onSelect;

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrightnessData.themeOf(context).popUp,
      ),
      child: BlocConsumer(
        buildWhen: (a, b) => b.item2?.isNotEmpty == true,
        bloc: mentionCubit,
        builder: (context, Tuple2<String, List<User>> tuple) =>
            ListView.builder(
          controller: scrollController,
          itemCount: tuple.item2.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) => _MentionItem(
            user: tuple.item2[index],
            keyword: tuple.item1,
            onSelect: onSelect,
          ),
        ),
        listener: (BuildContext context, Tuple2<String, List<User>> state) {
          if (!scrollController.hasClients) return;
          scrollController.jumpTo(0);
        },
      ),
    );
  }
}

class _MentionItem extends StatelessWidget {
  const _MentionItem({
    Key key,
    @required this.user,
    @required this.keyword,
    this.selected = false,
    this.onSelect,
  }) : super(key: key);

  final User user;
  final String keyword;
  final bool selected;
  final Function(User user) onSelect;

  @override
  Widget build(BuildContext context) => InteractableDecoratedBox.color(
        decoration: BoxDecoration(
          color: selected
              ? BrightnessData.themeOf(context).listSelected
              : Colors.transparent,
        ),
        tapDowningColor: BrightnessData.themeOf(context).listSelected,
        onTap: () => onSelect?.call(user),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              AvatarWidget(
                user: user,
                size: 32,
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HighlightText(
                    user.fullName,
                    style: TextStyle(
                      fontSize: 14,
                      color: BrightnessData.themeOf(context).text,
                    ),
                    highlightTextSpans: [
                      HighlightTextSpan(
                        keyword,
                        style: TextStyle(
                          color: BrightnessData.themeOf(context).accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  HighlightText(
                    user.identityNumber,
                    style: TextStyle(
                      fontSize: 12,
                      color: BrightnessData.themeOf(context).secondaryText,
                    ),
                    highlightTextSpans: [
                      HighlightTextSpan(
                        keyword,
                        style: TextStyle(
                          color: BrightnessData.themeOf(context).accent,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
