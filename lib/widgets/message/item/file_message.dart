import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset, Message;
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:mime/mime.dart';

import '../message_bubble.dart';
import '../message_datetime.dart';
import '../message_status.dart';

// todo status
class FileMessage extends StatelessWidget {
  const FileMessage({
    Key key,
    @required this.showNip,
    @required this.isCurrentUser,
    @required this.message,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;

  @override
  Widget build(BuildContext context) => MessageBubble(
        showNip: showNip,
        isCurrentUser: isCurrentUser,
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: BrightnessData.themeOf(context).listSelected,
                    ),
                    child: SizedBox.fromSize(
                      size: const Size.square(38),
                      child: Center(
                        child: Text(
                          extensionFromMime(lookupMimeType(message.mediaName))
                                  ?.toUpperCase() ??
                              'FILE',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                BrightnessData.themeOf(context).secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.mediaName,
                      style: TextStyle(
                        fontSize: 15,
                        color: BrightnessData.themeOf(context).text,
                      ),
                    ),
                    Text(
                      filesize(message.mediaSize),
                      style: TextStyle(
                        fontSize: 14,
                        color: BrightnessData.themeOf(context).secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MessageDatetime(dateTime: message.createdAt),
                if (isCurrentUser) MessageStatusWidget(status: message.status),
              ],
            ),
          ],
        ),
      );
}
