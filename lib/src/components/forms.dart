import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';
import 'button.dart';

class FField extends StatelessWidget {
  const FField({
    super.key,
    required this.label,
    required this.child,
    this.description,
    this.error,
    this.required = false,
  });
  final String label;
  final String? description, error;
  final Widget child;
  final bool required;
  @override
  Widget build(BuildContext context) {
    final c = FTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        child,
        if (description != null || error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(
              liveRegion: error != null,
              child: Text(
                error ?? description!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: error == null ? c.mutedForeground : c.destructive,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class FInput extends StatelessWidget {
  const FInput({
    super.key,
    this.controller,
    this.initialValue,
    this.placeholder,
    this.semanticLabel,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.onSaved,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.prefix,
    this.suffix,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.autovalidateMode = AutovalidateMode.disabled,
  }) : assert(controller == null || initialValue == null),
       assert(!obscureText || maxLines == 1);
  final TextEditingController? controller;
  final String? initialValue, placeholder, semanticLabel;
  final ValueChanged<String>? onChanged, onSubmitted;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final FocusNode? focusNode;
  final bool enabled, readOnly, obscureText, autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefix, suffix;
  final int? maxLines, minLines, maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final AutovalidateMode autovalidateMode;
  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: TextFormField(
      controller: controller,
      initialValue: initialValue,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      onSaved: onSaved,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      autovalidateMode: autovalidateMode,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: prefix,
        suffixIcon: suffix,
      ),
    ),
  );
}

class FTextarea extends StatelessWidget {
  const FTextarea({
    super.key,
    this.controller,
    this.initialValue,
    this.placeholder,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.minLines = 3,
    this.maxLines = 6,
    this.semanticLabel,
  });
  final TextEditingController? controller;
  final String? initialValue, placeholder, semanticLabel;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final int minLines, maxLines;
  @override
  Widget build(BuildContext context) => FInput(
    controller: controller,
    initialValue: initialValue,
    placeholder: placeholder,
    semanticLabel: semanticLabel,
    onChanged: onChanged,
    validator: validator,
    enabled: enabled,
    minLines: minLines,
    maxLines: maxLines,
    keyboardType: TextInputType.multiline,
  );
}

class FCheckbox extends StatelessWidget {
  const FCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
    this.tristate = false,
  }) : assert(tristate || value != null);
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final String? label, description;
  final bool tristate;
  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Checkbox(value: value, tristate: tristate, onChanged: onChanged);
    }
    return MergeSemantics(
      child: InkWell(
        borderRadius: FTheme.of(context).borderRadius,
        onTap: onChanged == null
            ? null
            : () => onChanged!(
                tristate
                    ? switch (value) {
                        false => true,
                        true => null,
                        null => false,
                      }
                    : !(value ?? false),
              ),
        child: Row(
          children: [
            Checkbox(value: value, tristate: tristate, onChanged: onChanged),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description!,
                      style: TextStyle(
                        color: FTheme.of(context).colors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FSwitch extends StatelessWidget {
  const FSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label, description;
  @override
  Widget build(BuildContext context) {
    final control = Switch(value: value, onChanged: onChanged);
    if (label == null) return control;
    return MergeSemantics(
      child: InkWell(
        borderRadius: FTheme.of(context).borderRadius,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label!,
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
                          color: FTheme.of(context).colors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            control,
          ],
        ),
      ),
    );
  }
}

class FRadioGroup<T> extends StatelessWidget {
  const FRadioGroup({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });
  final Map<T, String> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  @override
  Widget build(BuildContext context) => RadioGroup<T>(
    groupValue: value,
    onChanged: onChanged ?? (_) {},
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in items.entries)
          RadioListTile<T>(
            value: entry.key,
            title: Text(entry.value, style: const TextStyle(fontSize: 14)),
            enabled: onChanged != null,
            dense: true,
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: FTheme.of(context).borderRadius,
            ),
          ),
      ],
    ),
  );
}

class FSelect<T> extends StatelessWidget {
  const FSelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Select an option',
    this.errorText,
    this.semanticLabel,
  });
  final Map<T, String> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String placeholder;
  final String? errorText, semanticLabel;
  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: InputDecorator(
      decoration: InputDecoration(
        enabled: onChanged != null,
        errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: FTheme.of(context).borderRadius,
          dropdownColor: FTheme.of(context).colors.card,
          style: TextStyle(
            fontSize: 14,
            color: FTheme.of(context).colors.foreground,
          ),
          hint: Text(
            placeholder,
            style: TextStyle(
              fontSize: 14,
              color: FTheme.of(context).colors.mutedForeground,
            ),
          ),
          icon: const Icon(Icons.unfold_more, size: 16),
          onChanged: onChanged,
          items: items.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}

class FCombobox<T extends Object> extends StatefulWidget {
  const FCombobox({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    required this.labelOf,
    this.placeholder = 'Search options…',
    this.enabled = true,
  });
  final List<T> items;
  final T? value;
  final String Function(T) labelOf;
  final ValueChanged<T>? onChanged;
  final String placeholder;
  final bool enabled;
  @override
  State<FCombobox<T>> createState() => _FComboboxState<T>();
}

class _FComboboxState<T extends Object> extends State<FCombobox<T>> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value == null ? '' : widget.labelOf(widget.value!),
  );
  final FocusNode _focus = FocusNode();
  @override
  void didUpdateWidget(covariant FCombobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value == null
          ? ''
          : widget.labelOf(widget.value!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => RawAutocomplete<T>(
      textEditingController: _controller,
      focusNode: _focus,
      displayStringForOption: widget.labelOf,
      optionsBuilder: (value) => widget.items.where(
        (item) => widget
            .labelOf(item)
            .toLowerCase()
            .contains(value.text.toLowerCase()),
      ),
      onSelected: widget.onChanged,
      fieldViewBuilder: (context, controller, focus, submit) => FInput(
        controller: controller,
        focusNode: focus,
        placeholder: widget.placeholder,
        enabled: widget.enabled && widget.onChanged != null,
        onSubmitted: (_) => submit(),
        suffix: const Icon(Icons.unfold_more, size: 16),
      ),
      optionsViewBuilder: (context, select, options) {
        final entries = options.toList();
        final highlighted = AutocompleteHighlightedOption.of(context);
        final t = FTheme.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: t.colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: t.borderRadius,
              side: BorderSide(color: t.colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: constraints.hasBoundedWidth ? constraints.maxWidth : 280,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  padding: const EdgeInsets.all(4),
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (context, i) => ListTile(
                    dense: true,
                    selected: i == highlighted,
                    selectedTileColor: t.colors.accent,
                    title: Text(
                      widget.labelOf(entries[i]),
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () => select(entries[i]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class FSlider extends StatelessWidget {
  const FSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.label,
  });
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final String? label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
    ),
  );
}

/// A single editable field preserves native paste, selection, and OTP autofill.
class FInputOTP extends StatelessWidget {
  const FInputOTP({
    super.key,
    this.controller,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
  }) : assert(length > 0);
  final TextEditingController? controller;
  final int length;
  final ValueChanged<String>? onChanged, onCompleted;
  final bool enabled;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: TextInputType.number,
    autofillHints: const [AutofillHints.oneTimeCode],
    textAlign: TextAlign.center,
    maxLength: length,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(length),
    ],
    style: const TextStyle(
      fontFamily: 'monospace',
      fontSize: 24,
      letterSpacing: 12,
    ),
    decoration: InputDecoration(
      counterText: '',
      hintText: '•' * length,
      semanticCounterText: 'One time code',
    ),
    onChanged: (value) {
      onChanged?.call(value);
      if (value.length == length) onCompleted?.call(value);
    },
  );
}

class FDatePicker extends StatelessWidget {
  const FDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.placeholder = 'Pick a date',
  });
  final DateTime? value, firstDate, lastDate;
  final ValueChanged<DateTime>? onChanged;
  final String placeholder;
  @override
  Widget build(BuildContext context) => FButton(
    variant: FButtonVariant.outline,
    leading: const Icon(Icons.calendar_today_outlined),
    onPressed: onChanged == null
        ? null
        : () async {
            final first = firstDate ?? DateTime(1900);
            final last = lastDate ?? DateTime(2100);
            final date = value ?? DateTime.now();
            final result = await showDatePicker(
              context: context,
              initialDate: date.isBefore(first)
                  ? first
                  : date.isAfter(last)
                  ? last
                  : date,
              firstDate: first,
              lastDate: last,
            );
            if (result != null) onChanged!(result);
          },
    child: Text(
      value == null
          ? placeholder
          : MaterialLocalizations.of(context).formatMediumDate(value!),
    ),
  );
}

class FCalendar extends StatelessWidget {
  const FCalendar({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
  });
  final DateTime value, firstDate, lastDate;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) => CalendarDatePicker(
    key: ValueKey(value),
    initialDate: value,
    firstDate: firstDate,
    lastDate: lastDate,
    onDateChanged: onChanged,
  );
}

class FRangeSlider extends StatelessWidget {
  const FRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.label,
  });
  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;
  final double min, max;
  final int? divisions;
  final String? label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: RangeSlider(
      values: values,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
    ),
  );
}

class FDateRangePicker extends StatelessWidget {
  const FDateRangePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.placeholder = 'Pick a date range',
  });
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange>? onChanged;
  final DateTime? firstDate, lastDate;
  final String placeholder;
  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return FButton(
      variant: FButtonVariant.outline,
      leading: const Icon(Icons.date_range_outlined),
      onPressed: onChanged == null
          ? null
          : () async {
              final first = firstDate ?? DateTime(1900);
              final last = lastDate ?? DateTime(2100);
              final initial =
                  value != null &&
                      !value!.start.isBefore(first) &&
                      !value!.end.isAfter(last)
                  ? value
                  : null;
              final result = await showDateRangePicker(
                context: context,
                initialDateRange: initial,
                firstDate: first,
                lastDate: last,
              );
              if (result != null) onChanged!(result);
            },
      child: Text(
        value == null
            ? placeholder
            : '${localizations.formatMediumDate(value!.start)} – ${localizations.formatMediumDate(value!.end)}',
      ),
    );
  }
}

class FNativeSelect<T> extends FormField<T> {
  FNativeSelect({
    super.key,
    required Map<T, String> items,
    super.initialValue,
    ValueChanged<T?>? onChanged,
    super.onSaved,
    super.validator,
    super.enabled = true,
    super.autovalidateMode = AutovalidateMode.disabled,
    String placeholder = 'Select an option',
    String? semanticLabel,
  }) : super(
         builder: (state) => FSelect<T>(
           items: items,
           value: state.value,
           placeholder: placeholder,
           semanticLabel: semanticLabel,
           errorText: state.errorText,
           onChanged: enabled
               ? (value) {
                   state.didChange(value);
                   onChanged?.call(value);
                 }
               : null,
         ),
       );
}
