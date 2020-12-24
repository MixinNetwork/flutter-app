import 'package:flutter/material.dart';

class AvatarView extends StatelessWidget {
  const AvatarView({Key key, this.avatars, this.size})
      : assert(avatars.length > 0 && avatars.length <= 4),
        assert(size > 0),
        super(key: key);

  final List<String> avatars;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatars.length == 1) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatars[0]),
        backgroundColor: Colors.transparent,
      );
    } else if (avatars.length == 2) {
      return SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: _buildContent(),
          ));
    } else if (avatars.length == 3) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: _buildContent(),
        ),
      );
    } else {
      return SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: _buildContent(),
          ));
    }
  }

  Widget _buildContent() {
    if (avatars.length == 2) {
      return Row(
        children: [
          Image.network(
            avatars[0],
            width: size / 2,
            height: size,
            fit: BoxFit.cover,
          ),
          Image.network(
            avatars[1],
            width: size / 2,
            height: size,
            fit: BoxFit.cover,
          ),
        ],
      );
    } else if (avatars.length == 3) {
      return Row(
        children: [
          Image.network(
            avatars[0],
            width: size / 2,
            height: size,
            fit: BoxFit.cover,
          ),
          Column(
            children: [
              Image.network(
                avatars[1],
                width: size / 2,
                height: size / 2,
                fit: BoxFit.cover,
              ),
              Image.network(
                avatars[2],
                width: size / 2,
                height: size / 2,
                fit: BoxFit.cover,
              ),
            ],
          )
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(children: [
              Image.network(avatars[0]),
              Image.network(avatars[1]),
            ]),
          ),
          Expanded(
              flex: 1,
              child: Column(children: [
                Image.network(avatars[2]),
                Image.network(avatars[3]),
              ]))
        ],
      );
    }
  }
}
