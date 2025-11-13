import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlng/latlng.dart';
import 'package:map/map.dart' as map;

import '../../../../constants/resources.dart';
import '../../../../utils/uri_utils.dart';
import '../../../interactive_decorated_box.dart';
import '../../../mixin_image.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_datetime_and_status.dart';
import 'location_payload.dart';

class LocationMessageWidget extends HookConsumerWidget {
  const LocationMessageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = useMessageConverter(
      converter: (state) => state.content ?? '',
    );

    final location = useMemoized(
      () =>
          LocationPayload.fromJson(jsonDecode(content) as Map<String, dynamic>),
      [content],
    );
    return MessageBubble(
      padding: EdgeInsets.zero,
      outerTimeAndStatusWidget: const MessageDatetimeAndStatus(),
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
              map.MapLayout(
                builder: (context, transformer) => map.TileLayer(
                  builder: (BuildContext context, int x, int y, int z) {
                    final url =
                        'https://www.google.com/maps/vt/pb=!1m4!1m3!1i$z!2i$x!3i$y!2m3!1e0!2sm!3i420120488!3m7!2sen!5e1105!12m4!1e68!2m2!1sset!2sRoadmap!4e0!5m1!1e0!23i4111425';
                    return MixinImage.network(url);
                  },
                ),
                controller: map.MapController(
                  location: LatLng.degree(
                    location.latitude,
                    location.longitude,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.5),
                  child: SvgPicture.asset(
                    Resources.assetsImagesLocationMarkSvg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
