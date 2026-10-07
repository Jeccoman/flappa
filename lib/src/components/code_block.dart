import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'button.dart';

enum FCodeLanguage {
  dart('Dart', 'example.dart'),
  yaml('YAML', 'pubspec.yaml'),
  bash('Shell', 'Terminal'),
  json('JSON', 'data.json'),
  plain('Text', 'Snippet');

  const FCodeLanguage(this.label, this.filename);
  final String label, filename;
}

class FCodeBlock extends StatefulWidget {
  const FCodeBlock({
    super.key,
    required this.code,
    this.language = FCodeLanguage.dart,
    this.filename,
    this.showLineNumbers = true,
    this.maxHeight = 400,
    this.fontFamily = 'monospace',
    this.fontSize = 13,
    this.wrapLines = false,
    this.showWrapToggle = true,
  }) : assert(maxHeight > 0),
       assert(fontSize > 0);

  final String code;
  final FCodeLanguage language;
  final String? filename;
  final bool showLineNumbers;
  final bool wrapLines, showWrapToggle;

  final double maxHeight;
  final String fontFamily;
  final double fontSize;

  @override
  State<FCodeBlock> createState() => _FCodeBlockState();
}

class _FCodeBlockState extends State<FCodeBlock> {
  final _horizontal = ScrollController();
  final _vertical = ScrollController();
  Timer? _reset;
  String _copyState = 'Copy';
  late bool _wrapLines = widget.wrapLines;
  bool _copying = false;
  late List<_Token> _tokens = _tokenize(widget.code, widget.language);

  @override
  void didUpdateWidget(covariant FCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wrapLines != widget.wrapLines) _wrapLines = widget.wrapLines;
    if (widget.code != oldWidget.code ||
        widget.language != oldWidget.language) {
      _tokens = _tokenize(widget.code, widget.language);
      _reset?.cancel();
      _copyState = 'Copy';
    }
  }

  @override
  void dispose() {
    _reset?.cancel();
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    if (_copying) return;
    setState(() => _copying = true);
    final source = widget.code;
    String status;
    try {
      await Clipboard.setData(ClipboardData(text: source));
      status = 'Copied';
    } catch (_) {
      status = 'Retry copy';
    } finally {
      if (mounted) setState(() => _copying = false);
    }
    if (!mounted || source != widget.code) return;
    _reset?.cancel();
    setState(() => _copyState = status);
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copyState = 'Copy');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final colors = theme.colors;
    final background = dark ? const Color(0xFF101114) : const Color(0xFFFAFAFB);
    final syntax = _SyntaxColors(dark);
    final lines = '\n'.allMatches(widget.code).length + 1;
    final style = TextStyle(
      fontFamily: widget.fontFamily,
      fontFamilyFallback: const [
        'SFMono-Regular',
        'Menlo',
        'Consolas',
        'monospace',
      ],
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w400,
      height: 1.8,
      letterSpacing: 0,
      color: syntax.foreground,
    );
    final strut = StrutStyle.fromTextStyle(style, forceStrutHeight: true);
    return ClipRRect(
      borderRadius: theme.borderRadius,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: theme.borderRadius,
          side: BorderSide(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: colors.muted.withValues(alpha: dark ? .35 : .6),
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    Icon(
                      widget.language == FCodeLanguage.bash
                          ? Icons.terminal
                          : Icons.code,
                      size: 16,
                      color: colors.mutedForeground,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.filename ?? widget.language.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    if (constraints.maxWidth > 340) ...[
                      Text(
                        widget.language.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (widget.showWrapToggle)
                      MergeSemantics(
                        child: Semantics(
                          toggled: _wrapLines,
                          child: FButton(
                            onPressed: () =>
                                setState(() => _wrapLines = !_wrapLines),
                            variant: _wrapLines
                                ? FButtonVariant.secondary
                                : FButtonVariant.ghost,
                            size: FButtonSize.icon,
                            tooltip: _wrapLines
                                ? 'Scroll long lines'
                                : 'Wrap lines',
                            child: const Icon(Icons.wrap_text, size: 16),
                          ),
                        ),
                      ),
                    Semantics(
                      liveRegion: true,
                      child: FButton(
                        onPressed: _copying ? null : _copy,
                        variant: FButtonVariant.ghost,
                        size: FButtonSize.small,
                        tooltip: _copyState == 'Copied'
                            ? 'Copied to clipboard'
                            : 'Copy code',
                        leading: Icon(
                          _copyState == 'Copied'
                              ? Icons.check
                              : _copyState == 'Retry copy'
                              ? Icons.refresh
                              : Icons.copy_outlined,
                          size: 14,
                        ),
                        child: Text(
                          _copyState,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxHeight),
              child: Scrollbar(
                controller: _vertical,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.vertical,
                child: SingleChildScrollView(
                  controller: _vertical,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final span = TextSpan(
                            children: [
                              for (final token in _tokens)
                                TextSpan(
                                  text: token.text,
                                  style: TextStyle(
                                    color: syntax.color(token.kind),
                                  ),
                                ),
                            ],
                          );
                          final scaler = MediaQuery.textScalerOf(context);
                          final numberPainter = TextPainter(
                            text: TextSpan(text: '$lines', style: style),
                            textDirection: TextDirection.ltr,
                            textScaler: scaler,
                          )..layout();
                          final gutterWidth = widget.showLineNumbers
                              ? numberPainter.width.ceilToDouble() + 34
                              : 0.0;
                          numberPainter.dispose();
                          final contentWidth =
                              (constraints.maxWidth - gutterWidth).clamp(
                                1.0,
                                double.infinity,
                              );
                          var numbers = List.generate(
                            lines,
                            (index) => '${index + 1}',
                          ).join('\n');
                          if (_wrapLines && widget.showLineNumbers) {
                            final painter = TextPainter(
                              text: TextSpan(
                                style: style,
                                children: span.children,
                              ),
                              strutStyle: strut,
                              textDirection: TextDirection.ltr,
                              textScaler: scaler,
                            )..layout(maxWidth: contentWidth);
                            var line = 1;
                            var first = true;
                            numbers = [
                              for (final metric in painter.computeLineMetrics())
                                (() {
                                  final label = first ? '$line' : '';
                                  first = metric.hardBreak;
                                  if (metric.hardBreak) line++;
                                  return label;
                                })(),
                            ].join('\n');
                            painter.dispose();
                          }
                          final source = SelectableText.rich(
                            span,
                            style: style,
                            strutStyle: strut,
                            textDirection: TextDirection.ltr,
                          );
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.showLineNumbers)
                                ExcludeSemantics(
                                  child: SelectionContainer.disabled(
                                    child: Container(
                                      width: gutterWidth - 16,
                                      margin: const EdgeInsets.only(right: 16),
                                      padding: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                            color: colors.border,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        numbers,
                                        textAlign: TextAlign.right,
                                        softWrap: false,
                                        style: style.copyWith(
                                          color: syntax.color(_Kind.comment),
                                        ),
                                        strutStyle: strut,
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: _wrapLines
                                    ? source
                                    : Scrollbar(
                                        controller: _horizontal,
                                        thumbVisibility: true,
                                        notificationPredicate: (notification) =>
                                            notification.metrics.axis ==
                                            Axis.horizontal,
                                        child: SingleChildScrollView(
                                          controller: _horizontal,
                                          scrollDirection: Axis.horizontal,
                                          child: source,
                                        ),
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Kind { plain, comment, string, number, keyword, type, property, function }

class _Token {
  const _Token(this.text, this.kind);
  final String text;
  final _Kind kind;
}

class _SyntaxColors {
  const _SyntaxColors(this.dark);
  final bool dark;
  Color get foreground =>
      dark ? const Color(0xFFD4D4D8) : const Color(0xFF333842);
  Color color(_Kind kind) => switch (kind) {
    _Kind.plain => foreground,
    _Kind.comment => dark ? const Color(0xFF9096A2) : const Color(0xFF6B7280),
    _Kind.string => dark ? const Color(0xFFA5D6A7) : const Color(0xFF23733B),
    _Kind.number => dark ? const Color(0xFFF2BB88) : const Color(0xFF9A5014),
    _Kind.keyword => dark ? const Color(0xFFC4A7E7) : const Color(0xFF7C3AA5),
    _Kind.type => dark ? const Color(0xFF82D2D0) : const Color(0xFF176E77),
    _Kind.property => dark ? const Color(0xFF9CC9F5) : const Color(0xFF235FA4),
    _Kind.function => dark ? const Color(0xFFF0D58C) : const Color(0xFF865C16),
  };
}

const _keywords = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};
final _identifier = RegExp(r'[a-zA-Z_$][\w$]*');
final _number = RegExp(r'(?:0[xX][0-9a-fA-F]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)');
final _space = RegExp(r'\s');

List<_Token> _tokenize(String code, FCodeLanguage language) {
  if (language == FCodeLanguage.plain) return [_Token(code, _Kind.plain)];
  final tokens = <_Token>[];
  var i = 0;
  while (i < code.length) {
    final start = i;
    var kind = _Kind.plain;
    final char = code[i];
    final dart = language == FCodeLanguage.dart;
    final hashComment =
        language == FCodeLanguage.yaml || language == FCodeLanguage.bash;
    if ((dart && code.startsWith('//', i)) ||
        (hashComment &&
            char == '#' &&
            (i == 0 || _space.hasMatch(code[i - 1])))) {
      final end = code.indexOf('\n', i);
      i = end < 0 ? code.length : end;
      kind = _Kind.comment;
    } else if (dart && code.startsWith('/*', i)) {
      i += 2;
      var depth = 1;
      while (i < code.length && depth > 0) {
        if (code.startsWith('/*', i)) {
          depth++;
          i += 2;
        } else if (code.startsWith('*/', i)) {
          depth--;
          i += 2;
        } else {
          i++;
        }
      }
      kind = _Kind.comment;
    } else if (char == '"' ||
        char == "'" ||
        (dart &&
            char == 'r' &&
            i + 1 < code.length &&
            (code[i + 1] == '"' || code[i + 1] == "'"))) {
      final raw = char == 'r';
      if (raw) i++;
      final quote = code[i];
      final delimiter = dart && code.startsWith(quote * 3, i)
          ? quote * 3
          : quote;
      i += delimiter.length;
      while (i < code.length) {
        if (!raw && code[i] == '\\') {
          i = (i + 2).clamp(0, code.length);
        } else if (code.startsWith(delimiter, i)) {
          i += delimiter.length;
          break;
        } else {
          i++;
        }
      }
      var next = i;
      while (next < code.length && _space.hasMatch(code[next])) {
        next++;
      }
      kind =
          (language == FCodeLanguage.json || language == FCodeLanguage.yaml) &&
              next < code.length &&
              code[next] == ':'
          ? _Kind.property
          : _Kind.string;
    } else {
      final number = _number.matchAsPrefix(code, i);
      final word = _identifier.matchAsPrefix(code, i);
      if (number != null) {
        i = number.end;
        kind = _Kind.number;
      } else if (word != null) {
        i = word.end;
        final text = word.group(0)!;
        var next = i;
        while (next < code.length &&
            (code[next] == ' ' || code[next] == '\t')) {
          next++;
        }
        if ((dart && _keywords.contains(text)) ||
            const {'true', 'false', 'null'}.contains(text)) {
          kind = _Kind.keyword;
        } else if (next < code.length && code[next] == ':') {
          kind = _Kind.property;
        } else if (dart &&
            text.codeUnitAt(0) >= 65 &&
            text.codeUnitAt(0) <= 90) {
          kind = _Kind.type;
        } else if ((dart && next < code.length && code[next] == '(') ||
            (language == FCodeLanguage.bash &&
                const {
                  'dart',
                  'flutter',
                  'cd',
                  'git',
                  'echo',
                }.contains(text))) {
          kind = _Kind.function;
        }
      } else {
        i++;
      }
    }
    final text = code.substring(start, i);
    if (tokens.isNotEmpty && tokens.last.kind == kind) {
      final previous = tokens.removeLast();
      tokens.add(_Token(previous.text + text, kind));
    } else {
      tokens.add(_Token(text, kind));
    }
  }
  return tokens;
}
