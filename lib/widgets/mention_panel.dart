import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/mention_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuple/tuple.dart';

import 'avatar_view/avatar_view.dart';
import 'brightness_observer.dart';
import 'high_light_text.dart';
import 'interacter_decorated_box.dart';

class MentionPanel extends StatelessWidget {
  const MentionPanel({
    Key key,
    @required this.mentionCubit,
    this.width,
    @required this.onSelect,
  }) : super(key: key);

  final MentionCubit mentionCubit;
  final double width;
  final Function(User user) onSelect;

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 168,
        minWidth: width,
        maxWidth: width,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BrightnessData.themeOf(context).popUp,
        ),
        child: BlocConsumer(
          cubit: mentionCubit,
          builder: (context, Tuple2<String, List<User>> tuple) =>
              ListView.builder(
            controller: scrollController,
            itemCount: tuple.item2.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) => _MentionItem(
              user: tuple.item2[index],
              keyword: tuple.item1,
              onSelect: (user) {
                onSelect?.call(user);
                mentionCubit.clear();
              },
            ),
          ),
          listener: (BuildContext context, Tuple2<String, List<User>> state) {
            if (!scrollController.hasClients) return;
            scrollController.jumpTo(0);
          },
        ),
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
