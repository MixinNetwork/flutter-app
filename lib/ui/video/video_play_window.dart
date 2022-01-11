import 'package:dart_vlc/dart_vlc.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class VideoPlayerWindow extends HookWidget {
  const VideoPlayerWindow({
    Key? key,
    required this.path,
  }) : super(key: key);

  final String path;

  @override
  Widget build(BuildContext context) {
    final player = useMemoized(() => Player(id: 1001));
    useEffect(() {
      player.open(Media.file(File(path)));
      return player.dispose;
    }, [path]);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Video(player: player),
    );
  }
}
