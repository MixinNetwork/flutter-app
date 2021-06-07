import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../constants/resources.dart';
import 'brightness_observer.dart';

class SearchTextField extends StatelessWidget {
  const SearchTextField({
    Key? key,
    this.focusNode,
    this.controller,
    this.onChanged,
    this.fontSize = 14,
    this.hintText,
    this.autofocus = false,
  }) : super(key: key);

  final FocusNode? focusNode;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final double fontSize;

  final String? hintText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    const outlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.transparent,
      ),
      borderRadius: BorderRadius.all(
        Radius.circular(20.0),
      ),
      gapPadding: 0,
    );
    final backgroundColor = BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(245, 247, 250, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
    );
    final hintColor = BrightnessData.themeOf(context).secondaryText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: TextField(
        focusNode: focusNode,
        autofocus: autofocus,
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: BrightnessData.themeOf(context).text,
          fontSize: fontSize,
        ),
        scrollPadding: EdgeInsets.zero,
        decoration: InputDecoration(
          isDense: true,
          border: outlineInputBorder,
          focusedBorder: outlineInputBorder,
          enabledBorder: outlineInputBorder,
          filled: true,
          fillColor: backgroundColor,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          prefixIconConstraints:
              const BoxConstraints.expand(width: 40, height: 32),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: SvgPicture.asset(
              Resources.assetsImagesIcSearchSvg,
              color: hintColor,
            ),
          ),
          contentPadding: const EdgeInsets.only(right: 8),
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
