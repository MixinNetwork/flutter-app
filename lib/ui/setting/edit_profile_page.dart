import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/ui/home/bloc/auth_cubit.dart';
import 'package:flutter_app/widgets/app_bar.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

class EditProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final nameTextEditingController = TextEditingController();
    final bioTextEditingController = TextEditingController();
    return BlocConverter<AuthCubit, AuthState, Tuple2<String, String>>(
      converter: (state) => Tuple2(
        state.account.fullName,
        state.account.biography,
      ),
      immediatelyCallListener: true,
      listener: (context, state) {
        nameTextEditingController.text = state.item1;
        bioTextEditingController.text = state.item2;
      },
      child: Scaffold(
        backgroundColor: BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(246, 247, 250, 0.9),
          darkColor: const Color.fromRGBO(40, 44, 48, 1),
        ),
        appBar: MixinAppBar(
          title: 'Edit Profile',
          actions: [
            TextButton(
              onPressed: () {},
              child: const Text('Save'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              ClipOval(
                child: BlocConverter<AuthCubit, AuthState, String>(
                  converter: (state) => state.account.avatarUrl,
                  builder: (context, avatarUrl) => CachedNetworkImage(
                    imageUrl: avatarUrl,
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              BlocConverter<AuthCubit, AuthState, String>(
                converter: (state) => state.account.identityNumber,
                builder: (context, identityNumber) => Text(
                  'Mixin ID: $identityNumber',
                  style: TextStyle(
                    fontSize: 14,
                    color: BrightnessData.dynamicColor(
                      context,
                      const Color.fromRGBO(188, 190, 195, 1),
                      darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _Item(
                title: 'Name',
                controller: nameTextEditingController,
              ),
              const SizedBox(height: 32),
              _Item(
                title: 'Introduction',
                controller: bioTextEditingController,
              ),
              const SizedBox(height: 32),
              BlocConverter<AuthCubit, AuthState, String>(
                converter: (state) => state.account.phone,
                builder: (context, phone) => _Item(
                  title: 'Phone number',
                  controller: TextEditingController(text: phone),
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 70),
              BlocConverter<AuthCubit, AuthState, String>(
                converter: (state) => DateFormat.yMMMd()
                    .format(DateTime.tryParse(state.account.createdAt)),
                builder: (context, createdAt) => Text(
                  '$createdAt join',
                  style: TextStyle(
                    fontSize: 14,
                    color: BrightnessData.dynamicColor(
                      context,
                      const Color.fromRGBO(184, 189, 199, 1),
                      darkColor: const Color.fromRGBO(184, 189, 199, 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    Key key,
    this.title,
    this.controller,
    this.readOnly = false,
  }) : super(key: key);

  final String title;
  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    const outlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.transparent,
      ),
      borderRadius: BorderRadius.all(
        Radius.circular(8.0),
      ),
      gapPadding: 0,
    );

    final backgroundColor = readOnly
        ? BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(236, 238, 242, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.04),
          )
        : BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(245, 247, 250, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.08),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 90),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: BrightnessData.dynamicColor(
                context,
                const Color.fromRGBO(184, 189, 199, 1),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: readOnly,
            controller: controller,
            style: TextStyle(
              fontSize: 16,
              color: readOnly
                  ? BrightnessData.dynamicColor(
                      context,
                      const Color.fromRGBO(184, 189, 199, 1),
                      darkColor: const Color.fromRGBO(255, 255, 255, 0.1),
                    )
                  : BrightnessData.dynamicColor(
                      context,
                      const Color.fromRGBO(51, 51, 51, 1),
                      darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
                    ),
            ),
            decoration: InputDecoration(
              isDense: true,
              border: outlineInputBorder,
              focusedBorder: outlineInputBorder,
              enabledBorder: outlineInputBorder,
              filled: true,
              fillColor: backgroundColor,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
