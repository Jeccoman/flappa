import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';

void main() => runApp(const FlappaApp(home: ExampleScreen()));

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _updates = true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    showFToast(
      context,
      title: 'Preferences saved for ${_name.text.trim()}',
      description: _updates
          ? 'Product updates are on.'
          : 'Product updates are off.',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Flappa UI')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: FCard(
              title: const Text('Make it yours'),
              description: const Text('A few components to get started.'),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FField(
                      label: 'Display name',
                      required: true,
                      child: FInput(
                        controller: _name,
                        placeholder: 'Your name',
                        semanticLabel: 'Display name',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter your name'
                            : null,
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FSwitch(
                      value: _updates,
                      onChanged: (value) => setState(() => _updates = value),
                      label: 'Product updates',
                    ),
                    const SizedBox(height: 20),
                    FButton(
                      onPressed: _save,
                      child: const Text('Save preferences'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
