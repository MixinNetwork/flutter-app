import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/widgets/action_button.dart';
import 'package:flutter_app/widgets/back_button.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'avatar_view/avatar_view.dart';

class ChatBar extends StatelessWidget {
  const ChatBar({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    final actionColor = BrightnessData.themeOf(context).icon;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BrightnessData.themeOf(context).primary,
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConverter<ConversationCubit, ConversationItem?, String?>(
      converter: (state) => state?.ownerIdentityNumber,
      when: (a, b) => b != null,
      builder: (context, id) => Text(
        id!,
        style: TextStyle(
          color: BrightnessData.themeOf(context).secondaryText,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _Name extends StatelessWidget {
  const _Name({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      BlocConverter<ConversationCubit, ConversationItem?, String?>(
        converter: (state) => state?.groupName?.trim().isNotEmpty == true
            ? state?.groupName
            : state?.name,
        when: (a, b) => b != null,
        builder: (context, name) => Text(
          name!,
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ConversationCubit, ConversationItem?>(
        buildWhen: (a, b) => b != null,
        builder: (context, conversation) => ConversationAvatarWidget(
          size: 50,
          conversation: conversation!,
        ),
      );
}
