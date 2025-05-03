import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

import '../constants/resources.dart';
import '../utils/extension/extension.dart';

class RadioItem<T> extends StatelessWidget {
  const RadioItem({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.groupValue,
  });

  final Widget title;
  final T? groupValue;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => onChanged(value),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipOval(
            child: Container(
              color:
                  groupValue == value
                      ? context.theme.accent
                      : context.theme.secondaryText,
              height: 16,
              width: 16,
              alignment: const Alignment(0, -0.2),
              child: SvgPicture.asset(
                Resources.assetsImagesSelectedSvg,
                height: 10,
                width: 10,
              ),
            ),
          ),
          const SizedBox(width: 30),
          DefaultTextStyle.merge(
            style: TextStyle(color: context.theme.text, fontSize: 16),
            child: title,
          ),
        ],
      ),
    ),
  );
}
