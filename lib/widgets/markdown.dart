import 'package:flutter/material.dart';
import 'package:html/dom.dart' as h;
import 'package:html/dom_parsing.dart';
import 'package:html/parser.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';

import '../utils/extension/extension.dart';
import '../utils/uri_utils.dart';
import 'cache_image.dart';

class MarkdownColumn extends StatelessWidget {
  const MarkdownColumn({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final widgets = MarkdownGenerator(
      textGenerator: (node, config, visitor) => CustomTextNode(
        node.textContent,
        config,
        visitor,
      ),
      generators: _kMixinGenerators,
    ).buildWidgets(
      data,
      config: _createMarkdownConfig(
        context: context,
        darkMode: context.brightness == Brightness.dark,
      ),
    );
    return ClipRect(
      child: DefaultTextStyle.merge(
        style: TextStyle(color: context.theme.text),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
        ),
      ),
    );
  }
}

class Markdown extends StatelessWidget {
  const Markdown({
    super.key,
    required this.data,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  final String data;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
        style: TextStyle(color: context.theme.text),
        child: MarkdownWidget(
          data: data,
          padding: padding,
          physics: physics,
          config: _createMarkdownConfig(
            context: context,
            darkMode: context.brightness == Brightness.dark,
          ),
          markdownGenerator: MarkdownGenerator(
            textGenerator: (node, config, visitor) => CustomTextNode(
              node.textContent,
              config,
              visitor,
            ),
            generators: _kMixinGenerators,
          ),
        ),
      );
}

MarkdownConfig _createMarkdownConfig({
  required BuildContext context,
  required bool darkMode,
}) =>
    MarkdownConfig(configs: [
      if (darkMode) ...[
        HrConfig.darkConfig,
        H2Config.darkConfig,
        H3Config.darkConfig,
        H4Config.darkConfig,
        H5Config.darkConfig,
        H6Config.darkConfig,
        PreConfig.darkConfig,
        PConfig.darkConfig,
        CodeConfig.darkConfig,
      ],
      _MixinH1Config(darkMode),
      ImgConfig(builder: (url, attributes) {
        double? width;
        double? height;
        if (attributes['width'] != null) {
          width = double.parse(attributes['width']!);
        }
        if (attributes['height'] != null) {
          height = double.parse(attributes['height']!);
        }
        final imageUrl = url;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: CacheImage(
            imageUrl,
            width: width,
            height: height,
          ),
        );
      }),
      LinkConfig(
          style: TextStyle(color: context.theme.accent),
          onTap: (href) {
            if (href.isEmpty) return;
            openUri(context, href);
          }),
      ListConfig(
        marker: (bool isOrdered, int depth, int index) => getDefaultMarker(
          isOrdered,
          depth,
          context.theme.text,
          index,
          8,
          MarkdownConfig(),
        ),
      )
    ]);

class _MixinH1Config extends HeadingConfig {
  _MixinH1Config(this.dark);

  final bool dark;

  @override
  HeadingDivider? get divider => null;

  @override
  TextStyle get style => TextStyle(
        fontSize: 32,
        height: 40 / 32,
        color: dark ? Colors.white : null,
        fontWeight: FontWeight.bold,
      );

  @override
  String get tag => MarkdownTag.h1.name;
}

final RegExp htmlRep = RegExp('<[^>]*>', multiLine: true);

/// parse [m.Node] to [h.Node]
/// https://github.com/asjqkkkk/markdown_widget/blob/1d549fd5c2d6b0172281d8bb66e367654b9d60f0/example/lib/markdown_custom/html_support.dart
List<SpanNode> _parseHtml(
  m.Text node, {
  ValueCallback<dynamic>? onError,
  WidgetVisitor? visitor,
  TextStyle? parentStyle,
}) {
  try {
    final text =
        node.textContent.replaceAll(RegExp(r'(\r?\n)|(\r?\t)|(\r)'), '');
    if (!text.contains(htmlRep)) return [TextNode(text: node.text)];
    final document = parseFragment(text);
    return HtmlToSpanVisitor(visitor: visitor, parentStyle: parentStyle)
        .toVisit(document.nodes.toList());
  } catch (e) {
    onError?.call(e);
    return [TextNode(text: node.text)];
  }
}

class HtmlElement extends m.Element {
  HtmlElement(super.tag, super.children, this.textContent);

  @override
  final String textContent;
}

class HtmlToSpanVisitor extends TreeVisitor {
  HtmlToSpanVisitor({WidgetVisitor? visitor, TextStyle? parentStyle})
      : visitor = visitor ?? WidgetVisitor(),
        parentStyle = parentStyle ?? const TextStyle();
  final List<SpanNode> _spans = [];
  final List<SpanNode> _spansStack = [];
  final WidgetVisitor visitor;
  final TextStyle parentStyle;

  List<SpanNode> toVisit(List<h.Node> nodes) {
    _spans.clear();
    for (final node in nodes) {
      final emptyNode = ConcreteElementNode(style: parentStyle);
      _spans.add(emptyNode);
      _spansStack.add(emptyNode);
      visit(node);
      _spansStack.removeLast();
    }
    final result = List.of(_spans);
    _spans.clear();
    _spansStack.clear();
    return result;
  }

  @override
  void visitText(h.Text node) {
    final last = _spansStack.last;
    if (last is ElementNode) {
      final textNode = TextNode(text: node.text);
      last.accept(textNode);
    }
  }

  @override
  void visitElement(h.Element node) {
    final localName = node.localName ?? '';
    final mdElement = m.Element(localName, []);
    mdElement.attributes.addAll(node.attributes.cast());
    var spanNode = visitor.getNodeByElement(mdElement, visitor.config);
    if (spanNode is! ElementNode) {
      final n = ConcreteElementNode(tag: localName)..accept(spanNode);
      spanNode = n;
    }
    final last = _spansStack.last;
    if (last is ElementNode) {
      last.accept(spanNode);
    }
    _spansStack.add(spanNode);
    for (final child in node.nodes.toList(growable: false)) {
      visit(child);
    }
    _spansStack.removeLast();
  }
}

class CustomTextNode extends ElementNode {
  CustomTextNode(this.text, this.config, this.visitor);

  final String text;
  final MarkdownConfig config;
  final WidgetVisitor visitor;

  @override
  void onAccepted(SpanNode parent) {
    final textStyle = config.p.textStyle.merge(parentStyle);
    children.clear();
    if (!text.contains(htmlRep)) {
      accept(TextNode(text: text, style: textStyle));
      return;
    }
    _parseHtml(
      m.Text(text),
      visitor:
          WidgetVisitor(config: visitor.config, generators: visitor.generators),
      parentStyle: parentStyle,
    ).forEach(accept);
  }
}

final _kMixinGenerators = <SpanNodeGeneratorWithTag>[
  SpanNodeGeneratorWithTag(
    tag: MarkdownTag.pre.name,
    generator: (e, config, visitor) => _MixinCodeBlockNode(
      e.textContent,
      config.pre,
    ),
  ),
];

class _MixinCodeBlockNode extends CodeBlockNode {
  _MixinCodeBlockNode(super.content, super.preConfig);

  @override
  InlineSpan build() {
    final splitContents = content.trim().split(RegExp(r'(\r?\n)|(\r?\t)|(\r)'));
    if (splitContents.last.isEmpty) splitContents.removeLast();
    final widget = Container(
      decoration: preConfig.decoration,
      margin: preConfig.margin,
      padding: preConfig.padding,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(splitContents.length, (index) {
          final currentContent = splitContents[index];
          return ProxyRichText(TextSpan(
            children: highLightSpans(
              currentContent,
              language: preConfig.language,
              theme: preConfig.theme,
              textStyle: style,
              styleNotMatched: preConfig.styleNotMatched,
            ),
          ));
        }),
      ),
    );
    return WidgetSpan(
        child: preConfig.wrapper?.call(widget, content) ?? widget);
  }
}
