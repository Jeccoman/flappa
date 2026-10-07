import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/theme.dart';
import 'button.dart';
import 'display.dart';
import 'forms.dart';

class FChoiceCard extends StatelessWidget {
  const FChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onChanged,
    this.description,
    this.multiple = false,
    this.focusNode,
    this.autofocus = false,
  });
  final FocusNode? focusNode;
  final bool autofocus;
  final String title;
  final String? description;
  final bool selected, multiple;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = FTheme.of(context);
    return Semantics(
      checked: selected,
      enabled: onChanged != null,
      inMutuallyExclusiveGroup: !multiple,
      child: Material(
        color: selected ? t.colors.accent : t.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: t.borderRadius,
          side: BorderSide(
            color: selected ? t.colors.primary : t.colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          focusNode: focusNode,
          autofocus: autofocus,
          onTap: onChanged == null ? null : () => onChanged!(!selected),
          child: Padding(
            padding: EdgeInsets.all(selected ? 13 : 14),
            child: Opacity(
              opacity: onChanged == null ? .5 : 1,
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      multiple
                          ? (selected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank)
                          : (selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked),
                      size: 20,
                      color: selected
                          ? t.colors.primary
                          : t.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (description != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              description!,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: t.colors.mutedForeground,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FQuestionChoice {
  const FQuestionChoice({
    required this.value,
    required this.label,
    this.description,
  });
  final String value, label;
  final String? description;
}

class FQuestionAnswer {
  FQuestionAnswer({
    Set<String> selected = const {},
    this.text = '',
    this.skipped = false,
  }) : selected = Set.unmodifiable(selected);
  final Set<String> selected;
  final String text;
  final bool skipped;
  bool get isEmpty => selected.isEmpty && text.trim().isEmpty;
}

class FQuestion {
  const FQuestion({
    required this.id,
    required this.title,
    this.description,
    this.choices = const [],
    this.multiple = false,
    this.required = true,
    this.allowText = false,
    this.placeholder = 'Write your answer…',
    this.validator,
  });
  final String id, title;
  final String? description;
  final List<FQuestionChoice> choices;
  final bool multiple, required, allowText;
  final String placeholder;
  final String? Function(FQuestionAnswer)? validator;
}

class FQuestionnaire extends StatefulWidget {
  const FQuestionnaire({
    super.key,
    required this.questions,
    required this.onSubmitted,
    this.initialAnswers = const {},
    this.onChanged,
    this.submitLabel = 'Submit answers',
    this.completedBuilder,
  });
  final List<FQuestion> questions;
  final Map<String, FQuestionAnswer> initialAnswers;
  final FutureOr<void> Function(Map<String, FQuestionAnswer>) onSubmitted;
  final ValueChanged<Map<String, FQuestionAnswer>>? onChanged;
  final String submitLabel;
  final WidgetBuilder? completedBuilder;
  @override
  State<FQuestionnaire> createState() => _FQuestionnaireState();
}

class _FQuestionnaireState extends State<FQuestionnaire> {
  late final Map<String, FQuestionAnswer> _answers = {...widget.initialAnswers};
  late final _text = TextEditingController(
    text: _answer(widget.questions.first).text,
  );
  int _index = 0;
  bool _submitting = false, _complete = false;
  String? _error;
  Map<String, FQuestionAnswer> get _snapshot =>
      Map.unmodifiable({for (final q in widget.questions) q.id: _answer(q)});
  FQuestionAnswer _answer(FQuestion q) {
    final value = _answers[q.id] ?? FQuestionAnswer();
    final valid = value.selected.where(
      (selected) => q.choices.any((choice) => choice.value == selected),
    );
    return FQuestionAnswer(
      selected: (q.multiple ? valid : valid.take(1)).toSet(),
      text: q.allowText ? value.text : '',
      skipped: !q.required && value.skipped,
    );
  }

  void _update(FQuestion q, FQuestionAnswer value) {
    if (_text.text != value.text) _text.text = value.text;
    setState(() {
      _answers[q.id] = value;
      _error = null;
    });
    widget.onChanged?.call(_snapshot);
  }

  String? _validate(FQuestion q) {
    final answer = _answer(q);
    if (answer.skipped && !q.required) return null;
    if (q.required && answer.isEmpty) {
      return 'Choose or enter an answer to continue.';
    }
    return q.validator?.call(answer);
  }

  void _move(int index) {
    FocusScope.of(context).unfocus();
    _text.text = _answer(widget.questions[index]).text;
    setState(() {
      _index = index;
      _error = null;
    });
  }

  Future<void> _next() async {
    if (_submitting) return;
    final question = widget.questions[_index];
    final error = _validate(question);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_index < widget.questions.length - 1) {
      _move(_index + 1);
      return;
    }
    for (var i = 0; i < widget.questions.length; i++) {
      final problem = _validate(widget.questions[i]);
      if (problem != null) {
        _move(i);
        setState(() => _error = problem);
        return;
      }
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmitted(_snapshot);
      if (mounted) setState(() => _complete = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not submit your answers. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FQuestionnaire oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.questions.isNotEmpty);
    _index = _index.clamp(0, widget.questions.length - 1);
    _answers.removeWhere((id, _) => !widget.questions.any((q) => q.id == id));
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.questions.isNotEmpty);
    assert(
      widget.questions.map((q) => q.id).toSet().length ==
          widget.questions.length,
    );
    assert(widget.questions.every((q) => q.allowText || q.choices.isNotEmpty));
    assert(
      widget.questions.every(
        (q) => q.choices.map((c) => c.value).toSet().length == q.choices.length,
      ),
    );
    if (_complete) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.completedBuilder?.call(context) ??
              const FEmpty(
                title: 'All done',
                description: 'Your responses are ready.',
                icon: Icons.check_circle_outline,
              ),
          FButton(
            onPressed: () {
              setState(() {
                _answers.clear();
                _text.clear();
                _index = 0;
                _complete = false;
                _error = null;
              });
              widget.onChanged?.call(_snapshot);
            },
            variant: FButtonVariant.outline,
            child: const Text('Start again'),
          ),
        ],
      );
    }
    final q = widget.questions[_index];
    final answer = _answer(q);
    final c = FTheme.of(context).colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            'Question ${_index + 1} of ${widget.questions.length}',
            style: TextStyle(color: c.mutedForeground, fontSize: 12),
          ),
        ),
        const SizedBox(height: 10),
        FProgress(
          value: (_index + 1) / widget.questions.length,
          label: 'Question progress',
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            q.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -.4,
            ),
          ),
        ),
        if (q.description != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              q.description!,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: c.mutedForeground,
              ),
            ),
          ),
        const SizedBox(height: 20),
        for (final choice in q.choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FChoiceCard(
              title: choice.label,
              description: choice.description,
              multiple: q.multiple,
              selected: answer.selected.contains(choice.value),
              onChanged: _submitting
                  ? null
                  : (selected) {
                      final values = q.multiple
                          ? {...answer.selected}
                          : <String>{};
                      if (selected) {
                        values.add(choice.value);
                      } else {
                        values.remove(choice.value);
                      }
                      _update(
                        q,
                        FQuestionAnswer(
                          selected: values,
                          text: q.multiple ? answer.text : '',
                        ),
                      );
                    },
            ),
          ),
        if (q.allowText)
          FTextarea(
            controller: _text,
            placeholder: q.placeholder,
            semanticLabel: q.title,
            enabled: !_submitting,
            onChanged: (text) => _update(
              q,
              FQuestionAnswer(
                selected: q.multiple ? answer.selected : {},
                text: text,
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: c.destructive, fontSize: 13),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 8,
          children: [
            FButton(
              onPressed: _index == 0 || _submitting
                  ? null
                  : () => _move(_index - 1),
              variant: FButtonVariant.outline,
              child: const Text('Previous'),
            ),
            if (!q.required)
              FButton(
                onPressed: _submitting
                    ? null
                    : () {
                        _update(q, FQuestionAnswer(skipped: true));
                        _next();
                      },
                variant: FButtonVariant.ghost,
                child: const Text('Skip'),
              ),
            FButton(
              onPressed: _submitting ? null : _next,
              loading: _submitting,
              child: Text(
                _index == widget.questions.length - 1
                    ? widget.submitLabel
                    : 'Next',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
