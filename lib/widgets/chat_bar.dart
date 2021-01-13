import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/widgets/action_button.dart';
import 'package:flutter_app/widgets/back_button.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'avatar_view.dart';

class ChatBar extends StatelessWidget {
  const ChatBar({
    Key key,
    @required this.onPressed,
    this.isSelected,
  }) : super(key: key);

  final Function onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final actionColor = BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(47, 48, 50, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(255, 255, 255, 1),
          darkColor: const Color.fromRGBO(44, 49, 54, 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 14, bottom: 14),
        child: Row(children: [
          Builder(
            builder: (context) => ModalRoute.of(context)?.canPop ?? false
                ? MixinBackButton(
                    color: actionColor,
                    onTap: () {
                      BlocProvider.of<ConversationCubit>(context).emit(null);
                      Navigator.pop(context);
                    })
                : const SizedBox(width: 16),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                const _Avatar(),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Name(),
                    const _ID(),
                  ],
                ),
              ],
            ),
          ),
          ActionButton(
            name: Resources.assetsImagesIcSearchPng,
            color: actionColor,
          ),
          const SizedBox(width: 14),
          ActionButton(
            name: Resources.assetsImagesIcScreenPng,
            color: actionColor,
          ),
        ]),
      ),
    );
  }
}

class _ID extends StatelessWidget {
  const _ID({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConverter<ConversationCubit, ConversationItemsResult, String>(
      converter: (state) => state?.ownerIdentityNumber,
      builder: (context, id) => Text(
        id,
        style: TextStyle(
          color: BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(184, 189, 199, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
          ),
          fontSize: 14,
        ),
      ),
    );
  }
}

class _Name extends StatelessWidget {
  const _Name({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      BlocConverter<ConversationCubit, ConversationItemsResult, String>(
        converter: (state) => state?.name,
        when: (a, b) => b != null,
        builder: (context, name) => Text(
          name,
          style: TextStyle(
            color: BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(0, 0, 0, 1),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
            ),
            fontSize: 20,
          ),
        ),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      BlocConverter<ConversationCubit, ConversationItemsResult, List<String>>(
        converter: (state) => [state?.avatarUrl],
        when: (a, b) => b?.isNotEmpty == true,
        builder: (context, avatars) => AvatarsWidget(
          size: 50,
          avatars: avatars,
        ),
      );
}
