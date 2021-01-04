import 'package:flutter_app/bloc/simple_cubit.dart';
import 'package:flutter_app/ui/route.dart';

class SettingSelectedCubit extends SimpleCubit<String> {
  SettingSelectedCubit() : super(titlePageMap.keys.first);

  static const titlePageMap = {
    'Edit Profile': MixinRouter.editProfilePage,
    'Notification': MixinRouter.notificationPage,
    'Chat Backup': MixinRouter.chatBackupPage,
    'Data and Storage Usage': MixinRouter.dataAndStorageUsagePage,
    'Appearance': MixinRouter.appearancePage,
    'About': MixinRouter.aboutPage,
  };

}
