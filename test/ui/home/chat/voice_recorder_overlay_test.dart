import 'package:flutter/material.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/ui/home/chat/voice_recorder_bottom_bar.dart';
import 'package:flutter_app/utils/audio_message_player/audio_message_service.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' hide ChangeNotifierProvider;
import 'package:provider/provider.dart';

void main() {
  testWidgets('exiting record mode removes the overlay once', (tester) async {
    final notifier = VoiceRecorderNotifier(_FakeAudioMessagePlayService())
      ..value = const VoiceRecorderState(status: VoiceRecorderStatus.recording);
    addTearDown(() {
      notifier
        ..value = const VoiceRecorderState(status: VoiceRecorderStatus.idle)
        ..dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: BrightnessData(
          value: 0,
          brightnessThemeData: lightBrightnessThemeData,
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 56,
                  width: 600,
                  child: ChangeNotifierProvider<VoiceRecorderNotifier>.value(
                    value: notifier,
                    child: const VoiceRecorderBarOverlayComposition(
                      layoutWidth: 600,
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(VoiceRecorderBottomBar), findsOneWidget);

    notifier.value = const VoiceRecorderState(status: VoiceRecorderStatus.idle);
    await tester.pump();
    await tester.pump();

    expect(find.byType(VoiceRecorderBottomBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAudioMessagePlayService implements AudioMessagePlayService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
