import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/enum/message_action.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../brightness_observer.dart';

class SystemMessage extends StatelessWidget {
  const SystemMessage({
    Key? key,
    required this.message,
  }) : super(key: key);

  final MessageItem message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 8,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BrightnessData.dynamicColor(
                  context,
                  const Color.fromRGBO(202, 234, 201, 1),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 10,
                ),
                child: Builder(builder: (context) {
                  String text;
                  switch (message.actionName) {
                    case MessageAction.join:
                      text = Localization.of(context).chatGroupJoin(
                        message.participantRelationship == UserRelationship.me
                            ? Localization.of(context).you
                            : message.participantFullName,
                      );
                      break;
                    case MessageAction.exit:
                      text = Localization.of(context).chatGroupExit(
                        message.participantRelationship == UserRelationship.me
                            ? Localization.of(context).you
                            : message.participantFullName!,
                      );
                      break;
                    case MessageAction.add:
                      text = Localization.of(context).chatGroupAdd(
                        message.relationship == UserRelationship.me
                            ? Localization.of(context).you
                            : message.userFullName!,
                        message.participantRelationship == UserRelationship.me
                            ? Localization.of(context).you
                            : message.participantFullName!,
                      );
                      break;
                    case MessageAction.remove:
                      text = Localization.of(context).chatGroupRemove(
                        message.relationship == UserRelationship.me
                            ? Localization.of(context).you
                            : message.userFullName!,
                        message.participantRelationship == UserRelationship.me
                            ? Localization.of(context).you
                            : message.participantFullName!,
                      );
                      break;
                    case MessageAction.create:
                      text = Localization.of(context).chatGroupCreate(
                        message.relationship == UserRelationship.me
                            ? Localization.of(context).you
                            : message.userFullName!,
                        message.groupName!,
                      );
                      break;
                    // case MessageAction.update:
                    //   // todo May not be used anymore
                    //   break;
                    case MessageAction.role:
                      text = Localization.of(context).chatGroupRole;
                      break;
                    default:
                      text = Localization.of(context).chatNotSupport;
                      break;
                  }
                  return Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: BrightnessData.dynamicColor(
                        context,
                        const Color.fromRGBO(0, 0, 0, 1),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      );
}
