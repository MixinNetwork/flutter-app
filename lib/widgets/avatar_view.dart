import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AvatarsWidget extends StatelessWidget {
  const AvatarsWidget({Key key, this.avatars, this.size})
      : assert(avatars.length > 0),
        assert(size > 0),
        super(key: key);

  final List<String> avatars;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        size: Size.square(size),
        child: ClipOval(
          child: _AvatarPuzzlesWidget(avatars, size),
        ),
      );
}

class _AvatarPuzzlesWidget extends StatelessWidget {
  const _AvatarPuzzlesWidget(this.avatars, this.size, {Key key})
      : super(key: key);

  final List<String> avatars;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (avatars.length) {
      case 1:
        return _AvatarImage(avatars.single, size);
      case 2:
        return Row(
          children: avatars.map(_buildAvatarImage).toList(),
        );
      case 3:
        return Row(
          children: [
            Expanded(child: _AvatarImage(avatars[0], size)),
            Expanded(
              child: Column(
                children: avatars.sublist(1).map(_buildAvatarImage).toList(),
              ),
            ),
          ],
        );
      default:
        return Row(
          children: [
            avatars.sublist(0, 2),
            avatars.sublist(2),
          ]
              .map((e) => Expanded(
                    child: Column(
                      children: e.map(_buildAvatarImage).toList(),
                    ),
                  ))
              .toList(),
        );
    }
  }

  Widget _buildAvatarImage(String e) => Expanded(
        child: _AvatarImage(e, size),
      );
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage(
    this.src,
    this.size, {
    Key key,
  }) : super(key: key);

  final String src;
  final double size;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
        imageUrl: src,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
      );
}
