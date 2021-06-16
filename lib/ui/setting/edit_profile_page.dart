import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import '../../account/account_server.dart';
import '../../bloc/bloc_converter.dart';
import '../../generated/l10n.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/brightness_observer.dart';
import '../../widgets/dialog.dart';
import '../../widgets/toast.dart';
import '../home/bloc/multi_auth_cubit.dart';

class EditProfilePage extends HookWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nameTextEditingController = useTextEditingController();
    final bioTextEditingController = useTextEditingController();
    useEffect(() {
      context.read<AccountServer>().refreshSelf();
    });
    return BlocConverter<MultiAuthCubit, MultiAuthState,
        Tuple2<String?, String?>>(
      converter: (state) => Tuple2(
        state.current?.account.fullName,
        state.current?.account.biography,
      ),
      when: (a, b) => b?.item1 != null && b?.item2 != null,
      immediatelyCallListener: true,
      listener: (context, state) {
        nameTextEditingController.text = state.item1!;
        bioTextEditingController.text = state.item2!;
      },
      child: Scaffold(
        backgroundColor: BrightnessData.themeOf(context).background,
        appBar: MixinAppBar(
          title: Text(Localization.of(context).editProfile),
          actions: [
            MixinButton(
              onTap: () {
                runFutureWithToast(
                  context,
                  context.read<AccountServer>().updateAccount(
                        fullName: nameTextEditingController.text.trim(),
                        biography: bioTextEditingController.text.trim(),
                      ),
                );
              },
              backgroundTransparent: true,
              child: Center(child: Text(Localization.of(context).save)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Builder(builder: (context) {
                final account =
                    context.read<MultiAuthCubit>().state.current!.account;
                return AvatarWidget(
                  userId: account.userId,
                  name: account.fullName!,
                  avatarUrl: account.avatarUrl,
                  size: 100,
                );
              }),
              const SizedBox(height: 10),
              BlocConverter<MultiAuthCubit, MultiAuthState, String?>(
                converter: (state) => state.current?.account.identityNumber,
                when: (a, b) => b != null,
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
                title: Localization.of(context).name,
                controller: nameTextEditingController,
              ),
              const SizedBox(height: 32),
              _Item(
                title: Localization.of(context).introduction,
                controller: bioTextEditingController,
              ),
              const SizedBox(height: 32),
              BlocConverter<MultiAuthCubit, MultiAuthState, String?>(
                converter: (state) => state.current?.account.phone,
                when: (a, b) => b != null,
                builder: (context, phone) => _Item(
                  title: Localization.of(context).phoneNumber,
                  controller: TextEditingController(text: phone),
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 70),
              BlocConverter<MultiAuthCubit, MultiAuthState, String?>(
                converter: (state) {
                  final createdAt = state.current?.account.createdAt;
                  if (createdAt == null) return null;
                  return DateFormat.yMMMd().format(createdAt);
                },
                when: (a, b) => b != null,
                builder: (context, createdAt) => Text(
                  createdAt != null
                      ? Localization.of(context).pageEditProfileJoin(createdAt)
                      : '',
                  style: TextStyle(
                    fontSize: 14,
                    color: BrightnessData.themeOf(context).secondaryText,
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
    Key? key,
    required this.title,
    required this.controller,
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
            const Color.fromRGBO(255, 255, 255, 1),
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
              color: BrightnessData.themeOf(context).secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: readOnly,
            controller: controller,
            style: TextStyle(
              fontSize: 16,
              color: readOnly
                  ? BrightnessData.themeOf(context).secondaryText
                  : BrightnessData.themeOf(context).text,
            ),
            minLines: 1,
            maxLines: 10,
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
