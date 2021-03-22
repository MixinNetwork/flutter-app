import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/widgets/avatar_view/avatar_view.dart';
import 'package:flutter_app/widgets/forward_widget/bloc/forward_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_app/db/extension/user.dart';
import 'package:flutter_app/db/extension/conversation.dart';

import '../action_button.dart';
import '../brightness_observer.dart';
import '../high_light_text.dart';

class ForwardWidget extends StatelessWidget {
  const ForwardWidget();

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (BuildContext context) =>
            ForwardCubit(context.read<AccountServer>()),
        child: Builder(
          builder: (context) => Material(
            color: Colors.transparent,
            child: Container(
              width: 480,
              height: 600,
              padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ActionButton(
                            name: Resources.assetsImagesIcCloseSvg,
                            onTap: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            Localization.of(context).forward,
                            style: TextStyle(
                                color: BrightnessData.themeOf(context).text),
                          ),
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    margin: const EdgeInsets.only(top: 8, right: 8, left: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.center,
                    child: TextField(
                      onChanged: (string) =>
                          context.read<ForwardCubit>().keyword = string,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      scrollPadding: EdgeInsets.zero,
                      decoration: InputDecoration(
                        icon: SvgPicture.asset(
                          Resources.assetsImagesIcSearchSvg,
                          width: 20,
                        ),
                        contentPadding: const EdgeInsets.all(0),
                        isDense: true,
                        hintText: 'Search',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.08)),
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: BlocBuilder<ForwardCubit, ForwardState>(
                      builder: (context, state) => CustomScrollView(
                        slivers: [
                          if (state.recentConversations.isNotEmpty)
                            _ConversationsSection(
                              conversations: state.recentConversations,
                              keyword: state.keyword,
                              title:
                                  Localization.of(context).recentConversations,
                            ),
                          if (state.friends.isNotEmpty)
                            _UsersSection(
                              users: state.friends,
                              keyword: state.keyword,
                              title: Localization.of(context).contact,
                            ),
                          if (state.bots.isNotEmpty)
                            _UsersSection(
                              users: state.bots,
                              keyword: state.keyword,
                              title: Localization.of(context).bots,
                            ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
}

class _ConversationsSection extends StatelessWidget {
  const _ConversationsSection({
    required this.conversations,
    required this.keyword,
    required this.title,
    Key? key,
  }) : super(key: key);

  final List<ConversationItem> conversations;
  final String? keyword;
  final String title;

  @override
  Widget build(BuildContext context) => MultiSliver(
        pushPinnedChildren: true,
        children: [
          SliverPinnedHeader(
            child: Container(
              padding: const EdgeInsets.only(top: 10, bottom: 10, left: 14),
              color: BrightnessData.dynamicColor(
                context,
                const Color.fromRGBO(255, 255, 255, 1),
                darkColor: const Color.fromRGBO(62, 65, 72, 1),
              ),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: BrightnessData.themeOf(context).text,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final conversation = conversations[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(
                      context, Tuple2(conversation.conversationId, false)),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ConversationAvatarWidget(
                          conversation: conversation,
                          size: 50,
                        ),
                        const SizedBox(width: 16),
                        HighlightText(
                          conversation.groupName?.trim().isNotEmpty == true
                              ? conversation.groupName!
                              : conversation.name ?? '',
                          highlightTextSpans: [
                            if (keyword != null)
                              HighlightTextSpan(
                                keyword!,
                                style: TextStyle(
                                    color:
                                        BrightnessData.themeOf(context).accent),
                              ),
                          ],
                          style: TextStyle(
                            fontSize: 16,
                            color: BrightnessData.themeOf(context).text,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: conversations.length,
            ),
          ),
        ],
      );
}

class _UsersSection extends StatelessWidget {
  const _UsersSection({
    required this.users,
    required this.keyword,
    required this.title,
    Key? key,
  }) : super(key: key);

  final List<User> users;
  final String? keyword;
  final String title;

  @override
  Widget build(BuildContext context) => MultiSliver(
        pushPinnedChildren: true,
        children: [
          SliverPinnedHeader(
            child: Container(
              color: BrightnessData.dynamicColor(
                context,
                const Color.fromRGBO(255, 255, 255, 1),
                darkColor: const Color.fromRGBO(62, 65, 72, 1),
              ),
              padding: const EdgeInsets.only(top: 10, bottom: 10, left: 14),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: BrightnessData.themeOf(context).text,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final user = users[index];
                return GestureDetector(
                  onTap: () =>
                      Navigator.pop(context, Tuple2(user.userId, user.isBot)),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        AvatarWidget(
                          size: 50,
                          avatarUrl: user.avatarUrl,
                          name: user.fullName!,
                          userId: user.userId,
                        ),
                        const SizedBox(width: 16),
                        HighlightText(
                          user.fullName!,
                          highlightTextSpans: [
                            if (keyword != null)
                              HighlightTextSpan(
                                keyword!,
                                style: TextStyle(
                                    color:
                                        BrightnessData.themeOf(context).accent),
                              )
                          ],
                          style: TextStyle(
                            fontSize: 16,
                            color: BrightnessData.themeOf(context).text,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: users.length,
            ),
          ),
        ],
      );
}
