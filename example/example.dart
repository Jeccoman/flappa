import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';

void main() => runApp(const FlappaApp(home: ExampleScreen()));

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  bool _updates = true;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FField(
                    label: 'Display name',
                    child: FInput(placeholder: 'Your name'),
                  ),
                  const SizedBox(height: 20),
                  FSwitch(
                    value: _updates,
                    onChanged: (value) => setState(() => _updates = value),
                    label: 'Product updates',
                  ),
                  const SizedBox(height: 20),
                  FButton(
                    onPressed: () =>
                        showFToast(context, title: 'Preferences saved'),
                    child: const Text('Save preferences'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
