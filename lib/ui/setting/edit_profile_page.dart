import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';

import '../../bloc/bloc_converter.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/avatar_view/avatar_view.dart';

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
      context.accountServer.refreshSelf();
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
        backgroundColor: context.theme.background,
        appBar: MixinAppBar(
          title: Text(context.l10n.editProfile),
          actions: [
            MixinButton(
              onTap: () {
                runFutureWithToast(
                  context,
                  context.accountServer.updateAccount(
                    fullName: nameTextEditingController.text.trim(),
                    biography: bioTextEditingController.text.trim(),
                  ),
                );
              },
              backgroundTransparent: true,
              child: Center(child: Text(context.l10n.save)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Builder(builder: (context) {
                final account = context.multiAuthState.currentUser!;
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
                    color: context.dynamicColor(
                      const Color.fromRGBO(188, 190, 195, 1),
                      darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _Item(
                title: context.l10n.name,
                controller: nameTextEditingController,
              ),
              const SizedBox(height: 32),
              _Item(
                title: context.l10n.introduction,
                controller: bioTextEditingController,
              ),
              const SizedBox(height: 32),
              BlocConverter<MultiAuthCubit, MultiAuthState, String?>(
                converter: (state) => state.current?.account.phone,
                when: (a, b) => b != null,
                builder: (context, phone) => _Item(
                  title: context.l10n.phoneNumber,
                  controller: TextEditingController(text: phone),
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 70),
              BlocConverter<MultiAuthCubit, MultiAuthState, String?>(
                converter: (state) {
                  final createdAt = state.current?.account.createdAt;
                  if (createdAt == null) return null;
                  return DateFormat.yMMMd().format(createdAt.toLocal());
                },
                when: (a, b) => b != null,
                builder: (context, createdAt) => Text(
                  createdAt != null
                      ? context.l10n.pageEditProfileJoin(createdAt)
                      : '',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.theme.secondaryText,
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
        Radius.circular(8),
      ),
      gapPadding: 0,
    );

    final backgroundColor = readOnly
        ? context.dynamicColor(
            const Color.fromRGBO(236, 238, 242, 1),
            darkColor: const Color.fromRGBO(255, 255, 255, 0.04),
          )
        : context.dynamicColor(
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
              color: context.theme.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: readOnly,
            controller: controller,
            style: TextStyle(
              fontSize: 16,
              color:
                  readOnly ? context.theme.secondaryText : context.theme.text,
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
