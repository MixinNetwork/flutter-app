import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/home/chat_slide_page/share_media/file_page.dart';
import 'package:flutter_app/ui/home/chat_slide_page/share_media/media_page.dart';
import 'package:flutter_app/ui/home/chat_slide_page/share_media/post_page.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SharedMediaPage extends HookWidget {
  const SharedMediaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState(0);
    return Scaffold(
      backgroundColor: BrightnessData.themeOf(context).primary,
      appBar: MixinAppBar(
        title: Text(Localization.of(context).sharedMedia),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  IndexedStack(
                index: selectedIndex.value,
                children: [
                  MediaPage(maxHeight: constraints.maxHeight),
                  PostPage(maxHeight: constraints.maxHeight),
                  FilePage(maxHeight: constraints.maxHeight),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Localization.of(context).media,
              Localization.of(context).post,
              Localization.of(context).file,
            ]
                .asMap()
                .entries
                .map(
                  (e) => Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => selectedIndex.value = e.key,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontSize: 14,
                            color: e.key == selectedIndex.value
                                ? BrightnessData.themeOf(context).accent
                                : BrightnessData.themeOf(context).secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
