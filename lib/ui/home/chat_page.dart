import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/chat_bar.dart';
import 'package:flutter_app/widgets/input_container.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(237, 238, 238, 1),
            darkColor: const Color.fromRGBO(35, 39, 43, 1),
          ),
        ),
        child: BlocConverter<ConversationCubit, ConversationItem, bool>(
          converter: (state) => state != null,
          builder: (context, selected) => ChatContainer(
            onPressed: () {},
          ),
        ),
      );
}

class ChatContainer extends StatelessWidget {
  const ChatContainer({
    Key key,
    this.onPressed,
    this.isSelected,
  }) : super(key: key);

  final Function onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final messagesDao =
        Provider.of<AccountServer>(context).database.messagesDao;
    final windowHeight = MediaQuery.of(context).size.height;
    final itemScrollController = ItemScrollController();
    return BlocProvider(
      create: (context) => MessageBloc(
        messagesDao: messagesDao,
        conversationCubit: BlocProvider.of<ConversationCubit>(context),
        limit: windowHeight ~/ 20,
        jumpTo: ({index, alignment}) {
          if (itemScrollController.isAttached)
            itemScrollController.jumpTo(index: index, alignment: alignment);
        },
        // offset: 100,
        // index: 120,
        // alignment: 0.5,
      ),
      child: Builder(
        builder: (context) {
          BlocProvider.of<MessageBloc>(context)?.limit =
              MediaQuery.of(context).size.height ~/ 20;
          return Column(
            children: [
              ChatBar(onPressed: onPressed, isSelected: isSelected),
              Expanded(
                child: Navigator(
                  pages: [
                    MaterialPage(
                      child: Column(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (context) => BlocConverter<MessageBloc,
                                  PagingState<MessageItem>, int>(
                                // int.MaxValue
                                converter: (state) =>
                                    state?.count ?? 9223372036854775807,
                                builder: (context, count) =>
                                    ScrollablePositionedList.builder(
                                  key: Key(BlocProvider.of<MessageBloc>(context)
                                      .conversationId),
                                  initialScrollIndex:
                                      BlocProvider.of<MessageBloc>(context)
                                          .state
                                          .index,
                                  initialAlignment:
                                      BlocProvider.of<MessageBloc>(context)
                                          .state
                                          .alignment,
                                  addAutomaticKeepAlives: false,
                                  itemScrollController: itemScrollController,
                                  itemPositionsListener:
                                      BlocProvider.of<MessageBloc>(context)
                                          .itemPositionsListener,
                                  reverse: true,
                                  itemCount: count,
                                  itemBuilder:
                                      (BuildContext context, int index) =>
                                          MessageItemWidget(index: index),
                                ),
                              ),
                            ),
                          ),
                          const InputContainer()
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
