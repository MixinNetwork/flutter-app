import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = <({String path, List<Pattern> forbiddenPatterns})>[
    (
      path: 'lib/widgets/toast.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/conversation/mute_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/conversation/conversation_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/user/user_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/actions/create_circle_action.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/actions/create_group_conversation_action.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/actions/create_conversation_action.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/unknown_mixin_url_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/qr_code.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/az_selection.dart',
      forbiddenPatterns: [
        'Theme.of(context).textTheme',
      ],
    ),
    (
      path: 'lib/widgets/empty.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/radio.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/buttons.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/app_bar.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/pin_bubble.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message_status_icon.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/sticker_page/giphy_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/sticker_page/add_sticker_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/user/captcha_web_view_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/user/phone_number_input.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/user/verification_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/user/change_number_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/auth.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/user_selector/conversation_selector.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
        'BrightnessData.dynamicColor(context',
      ],
    ),
    (
      path: 'lib/widgets/menu.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
        'BrightnessData.dynamicColor(context',
        'BrightnessData.of(context)',
        'Theme.of(context).brightness',
        'MediaQuery.of(context)',
      ],
    ),
    (
      path: 'lib/app.dart',
      forbiddenPatterns: [
        'MediaQuery.of(context)',
        'MediaQuery.sizeOf(context)',
        'Localizations.localeOf(context)',
      ],
    ),
    (
      path: 'lib/utils/system/tray.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/backup_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/about_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/account_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/notification_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/storage_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/security_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/proxy_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/storage_usage_detail_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/video/video_preview_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/image/image_preview_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
        'MaterialLocalizations.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/send_message_dialog/send_message_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
        'BrightnessData.dynamicColor(context',
      ],
    ),
    (
      path: 'lib/widgets/message/item/transfer/transfer_message.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/transfer/safe_transfer_message.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path:
          'lib/widgets/message/item/transfer/inscription_message/inscription_message.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path:
          'lib/widgets/message/item/transfer/inscription_message/inscription_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/setting_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/account_delete_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/edit_profile_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
        'BrightnessData.dynamicColor(context',
      ],
    ),
    (
      path: 'lib/ui/landing/landing_failed.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/storage_usage_list_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/setting/log_page.dart',
      forbiddenPatterns: [
        'MaterialLocalizations.of(context)',
      ],
    ),
    (
      path: 'lib/ui/home/chat_slide_page/circle_manager_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
        'BrightnessData.dynamicColor(context',
      ],
    ),
    (
      path: 'lib/ui/home/chat_slide_page/group_invite/group_invite_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
        'BrightnessData.dynamicColor(context',
      ],
    ),
    (
      path: 'lib/ui/home/chat_slide_page/pin_messages_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/home/chat_slide_page/share_media/media_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/home/chat_slide_page/share_media/file_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/home/chat_slide_page/share_media/post_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/home/chat_slide_page/shared_media_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/home/chat_slide_page/shared_apps_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/home/chat_slide_page/groups_in_common_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/home/conversation/search_list.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/actions/command_palette_action.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/sticker_page/sticker_album_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/sticker_page/sticker_store.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
        'BrightnessData.dynamicColor(context',
      ],
    ),
    (
      path: 'lib/widgets/sticker_page/sticker_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
        'BrightnessData.dynamicColor(context',
      ],
    ),
    (
      path: 'lib/widgets/message/item/pin_message.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.dynamicColor(context',
      ],
    ),
    (
      path: 'lib/widgets/message/item/stranger_message.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/recall_message.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/unknown_message.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/waiting_message.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/secret_message.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
        'BrightnessData.dynamicColor(context',
      ],
    ),
    (
      path: 'lib/widgets/message/item/file_message.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/post_message.dart',
      forbiddenPatterns: [
        'MaterialLocalizations.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/transcript_message.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/transfer/transfer_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/transfer/safe_transfer_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/home/chat/selection_bottom_bar.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
        'BrightnessData.dynamicColor(context',
      ],
    ),
    (
      path: 'lib/ui/home/conversation/audio_player_bar.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/home/chat_slide_page/group_participants_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/home/slide_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
        'BrightnessData.of(context)',
      ],
    ),
    (
      path: 'lib/utils/device_transfer/device_transfer_dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/utils/device_transfer/device_transfer_widget.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/markdown.dart',
      forbiddenPatterns: [
        'Theme.of(context).brightness',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/dialog.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'MaterialLocalizations.of(context)',
        'BrightnessData.themeOf(context)',
        'BrightnessData.dynamicColor(context',
        'BrightnessData.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/high_light_text.dart',
      forbiddenPatterns: [
        'MaterialLocalizations.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/action_card/action_message.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/action_card/actions_card.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/contact_message_widget.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/text/text_message.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/item/action/action_message.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/message_day_time.dart',
      forbiddenPatterns: [
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/widgets/message/message_bubble.dart',
      forbiddenPatterns: [
        'Theme.of(context).brightness',
      ],
    ),
    (
      path:
          'lib/widgets/message/item/transfer/inscription_message/inscription_content.dart',
      forbiddenPatterns: [
        'MediaQuery.of(context)',
      ],
    ),
    (
      path: 'lib/widgets/brightness_observer.dart',
      forbiddenPatterns: [
        'MediaQuery.platformBrightnessOf(context)',
      ],
    ),
    (
      path: 'lib/utils/uri_utils.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/utils/file.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/utils/attachment/attachment_util.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/ui/provider/conversation_provider.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/db/dao/snapshot_dao.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
      ],
    ),
    (
      path: 'lib/ui/home/chat/chat_page.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
    (
      path: 'lib/ui/home/chat/image_editor.dart',
      forbiddenPatterns: [
        'Localization.of(context)',
        'BrightnessData.themeOf(context)',
      ],
    ),
  ];

  for (final entry in cases) {
    test(
      '${entry.path} uses ui runtime providers instead of shared .of(context)',
      () {
        final content = File(entry.path).readAsStringSync();
        for (final pattern in entry.forbiddenPatterns) {
          expect(
            content.contains(pattern),
            isFalse,
            reason:
                'Found forbidden shared runtime lookup: $pattern in ${entry.path}',
          );
        }
      },
    );
  }
}
