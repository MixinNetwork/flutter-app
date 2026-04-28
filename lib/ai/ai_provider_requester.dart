import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:genkit/genkit.dart' as genkit;
import 'package:genkit/plugin.dart' as genkit_plugin;
import 'package:genkit_anthropic/genkit_anthropic.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:genkit_openai/genkit_openai.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../utils/proxy.dart';
import 'model/ai_prompt_message.dart';
import 'model/ai_provider_config.dart';
import 'model/ai_provider_type.dart';

class AiProviderRequester {
  const AiProviderRequester();

  static const _aiToolMaxRounds = 8;
  static const _aiLogPreviewLength = 240;

  Future<String> requestText(
    AiProviderConfig config,
    List<AiPromptMessage> messages, {
    required ProxyConfig? proxy,
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
    required String? conversationId,
    List<genkit.Tool>? tools,
  }) async {
    d(
      'AI request start: provider=${config.type.name} model=${config.model} '
      'conversationId=$conversationId messages=${messages.length} '
      'tools=${tools?.length ?? 0}',
    );
    if (cancelToken.isCancelled) {
      throw Exception('AI generation stopped');
    }

    return _runWithProxy(
      proxy,
      () => _requestTextWithGenkit(
        config,
        messages,
        cancelToken: cancelToken,
        onContent: onContent,
        conversationId: conversationId,
        tools: tools,
      ),
    );
  }

  Future<String> _requestTextWithGenkit(
    AiProviderConfig config,
    List<AiPromptMessage> messages, {
    required CancelToken cancelToken,
    required Future<void> Function(String chunk) onContent,
    required String? conversationId,
    required List<genkit.Tool>? tools,
  }) async {
    final ai = _createGenkit(config);
    try {
      final cancelFuture = cancelToken.whenCancel.then<void>((_) {});
      final stream = ai.generateStream<dynamic, String>(
        messages: messages
            .map((message) => message.toGenkitMessage())
            .toList(growable: false),
        model: _modelFor(config),
        tools: tools,
        toolChoice: tools == null ? null : 'auto',
        maxTurns: _aiToolMaxRounds,
      );

      final subscriptionCompleter = Completer<void>();
      late final StreamSubscription<genkit.GenerateResponseChunk<String>>
      subscription;
      subscription = stream.listen(
        (chunk) {
          final text = chunk.text;
          if (text.isEmpty) {
            return;
          }
          subscription.pause();
          unawaited(
            Future<void>.sync(() => onContent(text))
                .catchError((Object error, StackTrace stackTrace) {
                  if (!subscriptionCompleter.isCompleted) {
                    subscriptionCompleter.completeError(error, stackTrace);
                  }
                })
                .whenComplete(subscription.resume),
          );
        },
        onError: subscriptionCompleter.completeError,
        onDone: subscriptionCompleter.complete,
        cancelOnError: true,
      );

      await Future.any([
        subscriptionCompleter.future,
        cancelFuture.then((_) async {
          await subscription.cancel();
          throw Exception('AI generation stopped');
        }),
      ]);

      final response = await Future.any([
        stream.onResult,
        cancelFuture.then<genkit.GenerateResponseHelper<String>>((_) {
          throw Exception('AI generation stopped');
        }),
      ]);
      final text = response.text.trim();
      if (text.isEmpty) {
        throw Exception('Empty AI response');
      }
      d(
        'AI request done: provider=${config.type.name} model=${config.model} '
        'conversationId=$conversationId text=${_previewText(text)}',
      );
      return text;
    } finally {
      await ai.shutdown();
    }
  }

  Future<String> _runWithProxy(
    ProxyConfig? proxy,
    Future<String> Function() fn,
  ) {
    if (proxy == null) {
      return fn();
    }
    if (proxy.type == ProxyType.socks5) {
      d('AI Genkit request does not support SOCKS5 proxy: ${proxy.toUri()}');
      return fn();
    }
    return HttpOverrides.runZoned(
      fn,
      createHttpClient: (context) =>
          HttpClient(context: context)..setProxy(proxy),
    );
  }

  genkit.Genkit _createGenkit(AiProviderConfig config) => genkit.Genkit(
    plugins: [_pluginFor(config)],
    model: _modelFor(config),
    isDevEnv: false,
  );

  genkit_plugin.GenkitPlugin _pluginFor(AiProviderConfig config) =>
      switch (config.type) {
        AiProviderType.openaiCompatible => openAI(
          apiKey: config.apiKey,
          baseUrl: _emptyToNull(config.baseUrl),
          models: [CustomModelDefinition(name: config.model)],
        ),
        AiProviderType.anthropic => anthropic(
          apiKey: config.apiKey,
          baseUrl: _emptyToNull(config.baseUrl),
        ),
        AiProviderType.gemini => googleAI(apiKey: config.apiKey),
      };

  genkit.ModelRef<dynamic> _modelFor(AiProviderConfig config) =>
      switch (config.type) {
        AiProviderType.openaiCompatible => openAI.model(config.model),
        AiProviderType.anthropic => anthropic.model(config.model),
        AiProviderType.gemini => googleAI.gemini(config.model),
      };

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

String _previewText(
  String? text, {
  int maxLength = AiProviderRequester._aiLogPreviewLength,
}) {
  final compact = text?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
  if (compact.isEmpty) {
    return '""';
  }
  if (compact.length <= maxLength) {
    return compact;
  }
  return '${compact.substring(0, maxLength)}...(${compact.length} chars)';
}
