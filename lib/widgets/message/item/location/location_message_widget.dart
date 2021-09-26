import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlng/latlng.dart';
import 'package:map/map.dart' as map;

import '../../../../constants/resources.dart';
import '../../../../db/mixin_database.dart';
import '../../../../utils/uri_utils.dart';
import '../../../cache_image.dart';
import '../../../interactive_decorated_box.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import 'location_payload.dart';

class LocationMessageWidget extends HookWidget {
  const LocationMessageWidget({
    Key? key,
    required this.message,
    required this.showNip,
    required this.isCurrentUser,
    this.pinArrow,
  }) : super(key: key);

  final bool showNip;
  final bool isCurrentUser;
  final MessageItem message;
  final Widget? pinArrow;

  @override
  Widget build(BuildContext context) {
    final location = useMemoized(
      () => LocationPayload.fromJson(
          jsonDecode(message.content!) as Map<String, dynamic>),
      [message.content],
    );
    return MessageBubble(
      messageId: message.messageId,
      isCurrentUser: isCurrentUser,
      padding: EdgeInsets.zero,
      outerTimeAndStatusWidget: MessageDatetimeAndStatus(
        showStatus: isCurrentUser,
        message: message,
      ),
      pinArrow: pinArrow,
      showNip: showNip,
      includeNip: true,
      clip: true,
      child: SizedBox(
        width: 260,
        height: 180,
        child: InteractiveDecoratedBox(
          onTap: () {
            var url =
                'https://www.google.com/maps/place/@${location.latitude},${location.longitude},17z?hl=zh-CN';
            if (location.address?.isNotEmpty == true) {
              url =
                  'https://www.google.com/maps/search/${Uri.encodeComponent(location.address!)}/@${location.latitude},${location.longitude},17z?hl=zh-CN';
            }
            openUri(context, url);
          },
          child: Stack(
            children: [
              map.Map(
                builder: (BuildContext context, int x, int y, int z) {
                  final url =
                      'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425';
                  return CacheImage(url);
                },
                controller: map.MapController(
                  location: LatLng(location.latitude, location.longitude),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.5),
                  child:
                      SvgPicture.asset(Resources.assetsImagesLocationMarkSvg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
