import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/assets.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/conversation_list_cubit.dart';
import 'package:flutter_app/widgets/action_button.dart';
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
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Builder(
            builder: (context) => ModalRoute.of(context)?.canPop ?? false
                ? Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionButton(
                      name: Assets.assetsImagesIcBackPng,
                      color: actionColor,
                      onTap: () {
                        BlocProvider.of<ConversationCubit>(context).emit(null);
                        Navigator.pop(context);
                      },
                    ),
                  )
                : const SizedBox(),
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
            name: Assets.assetsImagesIcSearchPng,
            color: actionColor,
          ),
          const SizedBox(width: 14),
          ActionButton(
            name: Assets.assetsImagesIcScreenPng,
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
    return BlocConverter<ConversationCubit, Conversation, String>(
      converter: (state) => state?.name,
      builder: (context, name) => Text(
        '19890604',
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
  Widget build(BuildContext context) {
    return BlocConverter<ConversationCubit, Conversation, String>(
      converter: (state) => state?.name,
      builder: (context, name) => Text(
        name ?? '',
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
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConverter<ConversationCubit, Conversation, List<String>>(
      converter: (state) => state?.avatars,
      builder: (context, avatars) => AvatarsWidget(
        size: 50,
        avatars: avatars,
      ),
    );
  }
}
