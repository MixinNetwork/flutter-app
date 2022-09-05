import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';

import '../../api/giphy_api.dart';
import '../../api/giphy_vo/giphy_gif.dart';
import '../../ui/home/bloc/conversation_cubit.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/logger.dart';
import '../cache_image.dart';
import '../clamping_custom_scroll_view/scroller_scroll_controller.dart';
import '../interactive_decorated_box.dart';
import '../search_text_field.dart';

class GiphyPage extends HookWidget {
  const GiphyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();

    final searchKeywordController = useStreamController<String>();

    useEffect(() {
      void onTextChanged() {
        searchKeywordController.add(textEditingController.text.trim());
      }

      textEditingController.addListener(onTextChanged);
      return () {
        textEditingController.removeListener(onTextChanged);
      };
    }, [textEditingController]);

    final keyword = useMemoizedStream(
      () => searchKeywordController.stream.debounceTime(
        const Duration(seconds: 1),
      ),
    ).data;

    return Column(
      children: [
        _SearchBar(controller: textEditingController),
        Divider(
          color: context.theme.divider,
          height: 1,
        ),
        const SizedBox(height: 12),
        Expanded(child: _GiphyGifsLoader(query: keyword ?? ''))
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: SearchTextField(
            controller: controller,
            hintText: context.l10n.search,
          ),
        ),
      );
}

class _GiphyGifsLoader extends HookWidget {
  const _GiphyGifsLoader({this.query});

  final String? query;

  @override
  Widget build(BuildContext context) => _GifGridView(
        loadGifs: (limit, offset) {
          d('loadGifs($query): $limit, $offset');
          if (query == null || query!.isEmpty) {
            return GiphyApi.instance
                .trendingGifs(limit, offset)
                .then((value) => value.data);
          } else {
            return GiphyApi.instance
                .search(query!, limit, offset)
                .then((value) => value.data);
          }
        },
        key: ValueKey(query),
      );
}

const _limit = 51;

class _GifGridView extends HookWidget {
  const _GifGridView({required this.loadGifs, super.key});

  final Future<List<GiphyGif>> Function(int limit, int offset) loadGifs;

  @override
  Widget build(BuildContext context) {
    final hasMore = useState(true);

    final loading = useState(false);

    final gifs = useState(const <GiphyGif>[]);

    Future<void> load() async {
      if (loading.value || !hasMore.value) {
        return;
      }
      loading.value = true;
      try {
        final data = await loadGifs(_limit, gifs.value.length);
        hasMore.value = data.length >= _limit;
        gifs.value = gifs.value + data;
      } catch (error, stacktrace) {
        e("_GifGridView's error: $error, $stacktrace");
      } finally {
        loading.value = false;
      }
    }

    // initial load.
    useMemoized(load);

    final controller = useMemoized(ScrollerScrollController.new);
    useEffect(() {
      void onScroll() {
        if (controller.position.pixels == controller.position.maxScrollExtent) {
          d('onScroll: load more');
          load();
        }
      }

      controller.addListener(onScroll);
      return () => controller.removeListener(onScroll);
    }, [controller]);

    if (gifs.value.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      controller: controller,
      itemCount: gifs.value.length,
      itemBuilder: (context, index) => _GifItem(gif: gifs.value[index]),
    );
  }
}

class _GifItem extends HookWidget {
  const _GifItem({required this.gif});

  final GiphyGif gif;

  @override
  Widget build(BuildContext context) {
    final previewImage = gif.images.fixedWidthDownsampled;
    final sendImage = gif.images.fixedWidth;
    final playing = useImagePlaying(context);

    return InteractiveDecoratedBox(
      onTap: () async {
        final accountServer = context.accountServer;
        final conversationItem = context.read<ConversationCubit>().state;
        if (conversationItem == null) return;
        await accountServer.sendImageMessageByUrl(
          conversationItem.encryptCategory,
          sendImage.url,
          previewImage.url,
          conversationId: conversationItem.conversationId,
          recipientId: conversationItem.user?.userId,
          width: int.tryParse(sendImage.width),
          height: int.tryParse(sendImage.height),
        );
      },
      child: CacheImage(
        previewImage.url,
        controller: playing,
        placeholder: () => ColoredBox(color: context.theme.secondaryText),
      ),
    );
  }
}
