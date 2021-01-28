import 'package:flutter/widgets.dart';

double dpToPx(BuildContext context, double dp) =>
    dp * MediaQuery.of(context).devicePixelRatio;

double pxToDp(BuildContext context, num px) =>
    px / MediaQuery.of(context).devicePixelRatio;
