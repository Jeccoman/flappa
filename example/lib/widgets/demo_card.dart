import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';

class DemoCard extends StatefulWidget {
  const DemoCard({
    super.key,
    required this.title,
    required this.description,
    required this.code,
    required this.child,
  });
  final String title, description, code;
  final Widget child;
  @override
  State<DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<DemoCard> {
  bool _code = false;
  @override
  Widget build(BuildContext context) => FCard(
    title: Text(widget.title),
    description: Text(widget.description),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.child,
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            expanded: _code,
            child: FButton(
              onPressed: () => setState(() => _code = !_code),
              variant: FButtonVariant.ghost,
              size: FButtonSize.small,
              leading: const Icon(Icons.code, size: 14),
              tooltip: _code ? 'Hide code' : 'Show code',
              child: Text(_code ? 'Hide code' : 'Show code'),
            ),
          ),
        ),
        if (_code) ...[const SizedBox(height: 12), CodeBlock(widget.code)],
      ],
    ),
  );
}

class CodeBlock extends StatelessWidget {
  const CodeBlock(
    this.code, {
    super.key,
    this.language = FCodeLanguage.dart,
    this.filename,
  });
  final String code;
  final FCodeLanguage language;
  final String? filename;
  @override
  Widget build(BuildContext context) => FCodeBlock(
    code: code,
    language: language,
    filename: filename,
    fontFamily: 'JetBrainsMono',
  );
}
