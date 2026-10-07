import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'widgets/demo_card.dart';

class _DemoGrid extends StatelessWidget {
  const _DemoGrid({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth > 760 ? 2 : 1;
      final width = (constraints.maxWidth - (columns - 1) * 20) / columns;
      return Wrap(
        spacing: 20,
        runSpacing: 20,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

class CompositionDemos extends StatefulWidget {
  const CompositionDemos({super.key});
  @override
  State<CompositionDemos> createState() => _CompositionDemosState();
}

class _CompositionDemosState extends State<CompositionDemos> {
  int _zoom = 100;
  final _search = TextEditingController();
  final _project = TextEditingController();
  final _focus = FocusNode();
  final _form = GlobalKey<FormState>();
  String? _region;
  @override
  void dispose() {
    _search.dispose();
    _project.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _notify(String title) => showFToast(context, title: title);

  @override
  Widget build(BuildContext context) => _DemoGrid(
    children: [
      DemoCard(
        title: 'Button group',
        description: 'Related actions, joined at the edges.',
        code:
            "FButtonGroup(\n  label: 'Zoom controls',\n  children: [\n    FButton(onPressed: zoomOut, child: const Icon(Icons.remove)),\n    FButton(onPressed: resetZoom, child: Text('\$zoom%')),\n    FButton(onPressed: zoomIn, child: const Icon(Icons.add)),\n  ],\n)",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FButtonGroup(
              label: 'Zoom controls',
              children: [
                FButton(
                  onPressed: _zoom > 25
                      ? () => setState(() => _zoom -= 25)
                      : null,
                  variant: FButtonVariant.ghost,
                  size: FButtonSize.icon,
                  tooltip: 'Zoom out',
                  child: const Icon(Icons.remove),
                ),
                FButton(
                  onPressed: () => setState(() => _zoom = 100),
                  variant: FButtonVariant.ghost,
                  tooltip: 'Reset zoom',
                  child: Text('$_zoom%'),
                ),
                FButton(
                  onPressed: _zoom < 200
                      ? () => setState(() => _zoom += 25)
                      : null,
                  variant: FButtonVariant.ghost,
                  size: FButtonSize.icon,
                  tooltip: 'Zoom in',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FButtonGroup(
              axis: Axis.vertical,
              label: 'Document actions',
              children: [
                FButton(
                  onPressed: () => _notify('Document saved'),
                  variant: FButtonVariant.ghost,
                  leading: const Icon(Icons.save_outlined),
                  child: const Text('Save draft'),
                ),
                FButton(
                  onPressed: () => _notify('Document archived'),
                  variant: FButtonVariant.ghost,
                  leading: const Icon(Icons.archive_outlined),
                  child: const Text('Archive'),
                ),
              ],
            ),
          ],
        ),
      ),
      DemoCard(
        title: 'Input group',
        description: 'Icons, actions, and helper content in one field.',
        code:
            "FInputGroup(\n  leading: const Icon(Icons.search),\n  trailing: FButton(onPressed: search, child: const Text('Go')),\n  child: FInput(controller: query, placeholder: 'Search projects'),\n)",
        child: Column(
          children: [
            FInputGroup(
              leading: const Icon(Icons.search),
              trailing: FButton(
                onPressed: () => _notify(
                  _search.text.trim().isEmpty
                      ? 'Enter a search term'
                      : 'Searching for ${_search.text}',
                ),
                variant: FButtonVariant.ghost,
                size: FButtonSize.small,
                child: const Text('Go'),
              ),
              child: FInput(
                controller: _search,
                placeholder: 'Search projects',
                semanticLabel: 'Search projects',
              ),
            ),
            const SizedBox(height: 20),
            const FInputGroup(
              leading: Text('https://'),
              trailing: Text('.com'),
              child: FInput(
                placeholder: 'your-site',
                semanticLabel: 'Site name',
              ),
            ),
          ],
        ),
      ),
      DemoCard(
        title: 'Fieldset, label & native select',
        description: 'Group fields with validation and a proper reset.',
        code:
            "Form(\n  key: formKey,\n  child: FFieldSet(\n    legend: 'Project settings',\n    children: [\n      FNativeSelect<String>(\n        items: const {'eu': 'Europe', 'af': 'Africa'},\n        validator: (value) => value == null ? 'Choose a region' : null,\n      ),\n    ],\n  ),\n)",
        child: Form(
          key: _form,
          child: FFieldSet(
            legend: 'Project settings',
            description: 'Choose where your project will live.',
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FLabel('Project name', focusNode: _focus),
                  const SizedBox(height: 8),
                  FInput(
                    controller: _project,
                    focusNode: _focus,
                    placeholder: 'My next idea',
                    semanticLabel: 'Project name',
                  ),
                ],
              ),
              FField(
                label: 'Region',
                required: true,
                child: FNativeSelect<String>(
                  items: const {
                    'eu': 'Europe',
                    'af': 'Africa',
                    'as': 'Asia Pacific',
                  },
                  placeholder: 'Choose a region',
                  semanticLabel: 'Region',
                  validator: (value) =>
                      value == null ? 'Choose a region' : null,
                  onSaved: (value) => _region = value,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  FButton(
                    onPressed: () {
                      if (_form.currentState!.validate()) {
                        _form.currentState!.save();
                        _notify('Settings saved for $_region');
                      }
                    },
                    child: const Text('Save settings'),
                  ),
                  FButton(
                    onPressed: () {
                      _form.currentState!.reset();
                      _project.clear();
                    },
                    variant: FButtonVariant.outline,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      DemoCard(
        title: 'Item & item group',
        description: 'Flexible rows for files, people, or settings.',
        code:
            "FItemGroup(children: [\n  FItem(\n    title: const Text('Design system'),\n    description: const Text('Updated a moment ago'),\n    leading: const Icon(Icons.folder_outlined),\n    onPressed: openProject,\n  ),\n])",
        child: FItemGroup(
          children: [
            FItem(
              title: const Text('Design system'),
              description: const Text('Updated a moment ago'),
              leading: const Icon(Icons.folder_outlined),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onPressed: () => _notify('Design system opened'),
            ),
            FItem(
              title: const Text('Sofia Chen'),
              description: const Text('Ready to review your changes'),
              leading: const FAvatar(fallback: 'SC', size: 32),
              variant: FItemVariant.muted,
              onPressed: () => _notify('Profile opened'),
            ),
            const FItem(
              title: Text('Archived project'),
              description: Text('This project is read-only'),
              leading: Icon(Icons.lock_outline),
              enabled: false,
            ),
          ],
        ),
      ),
      const DemoCard(
        title: 'Typography',
        description: 'A consistent rhythm for headings and body text.',
        code:
            "const FTypography('Make room for ideas.', variant: FTypographyVariant.h3);\nconst FTypography('Small details make a difference.');\nconst FTypography('Built to be yours.', variant: FTypographyVariant.quote);",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FTypography('Make room for ideas.', variant: FTypographyVariant.h3),
            SizedBox(height: 12),
            FTypography(
              'A little structure helps your content speak for itself.',
              variant: FTypographyVariant.lead,
            ),
            SizedBox(height: 16),
            FTypography(
              'Use a shared type scale to keep titles, descriptions, and supporting text consistent across your app.',
            ),
            SizedBox(height: 16),
            FTypography(
              'Built to be yours.',
              variant: FTypographyVariant.quote,
            ),
            SizedBox(height: 16),
            FTypography(
              'A quieter note at the end.',
              variant: FTypographyVariant.muted,
            ),
          ],
        ),
      ),
      DemoCard(
        title: 'Aspect ratio',
        description: 'Consistent proportions for media and previews.',
        code:
            "FAspectRatio(\n  ratio: 16 / 9,\n  child: Image.asset('assets/cover.jpg', fit: BoxFit.cover),\n)",
        child: FAspectRatio(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  FTheme.of(context).colors.muted,
                  FTheme.of(context).colors.border,
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.landscape_outlined, size: 40),
                  SizedBox(height: 8),
                  Text(
                    '16:9',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      DemoCard(
        title: 'Draggable drawer',
        description: 'Drag to expand. Scroll to explore.',
        code:
            "showFDrawer<void>(\n  context: context,\n  builder: (context, controller) => FDrawer(\n    controller: controller,\n    title: 'Activity',\n    child: activityList,\n  ),\n);",
        child: Align(
          alignment: Alignment.centerLeft,
          child: FButton(
            onPressed: () => showFDrawer<void>(
              context: context,
              builder: (context, controller) => FDrawer(
                title: 'Recent activity',
                description: 'Drag the panel to see more of your workspace.',
                controller: controller,
                actions: [
                  FButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
                child: FItemGroup(
                  dividers: true,
                  children: [
                    for (var i = 1; i <= 12; i++)
                      FItem(
                        variant: FItemVariant.plain,
                        title: Text('Project update $i'),
                        description: const Text(
                          'Your team is making progress.',
                        ),
                        leading: const Icon(Icons.history),
                      ),
                  ],
                ),
              ),
            ),
            variant: FButtonVariant.outline,
            leading: const Icon(Icons.vertical_align_top),
            child: const Text('Open activity drawer'),
          ),
        ),
      ),
    ],
  );
}

class MessagingDemos extends StatefulWidget {
  const MessagingDemos({super.key});
  @override
  State<MessagingDemos> createState() => _MessagingDemosState();
}

class _MessagingDemosState extends State<MessagingDemos> {
  final _input = TextEditingController();
  final _messages = <({String text, bool outgoing})>[
    (
      text: 'Hey! How is the new component library coming along?',
      outgoing: false,
    ),
    (text: 'The foundations are ready. Want to take a look?', outgoing: true),
    (
      text: 'Absolutely. The small details already feel great.',
      outgoing: false,
    ),
  ];
  bool _attachment = true;
  double _progress = .65;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add((text: text, outgoing: true)));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) => _DemoGrid(
    children: [
      DemoCard(
        title: 'Message & message scroller',
        description: 'Follows new messages when you’re already at the end.',
        code:
            "SizedBox(\n  height: 320,\n  child: FMessageScroller(children: [\n    const FMessage(author: 'Sofia', child: Text('Hello!')),\n    const FMessage(outgoing: true, child: Text('Hey there.')),\n  ]),\n)",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 330,
              decoration: BoxDecoration(
                border: Border.all(color: FTheme.of(context).colors.border),
                borderRadius: FTheme.of(context).borderRadius,
              ),
              child: FMessageScroller(
                children: [
                  for (var i = 0; i < _messages.length; i++)
                    FMessage(
                      key: ValueKey(i),
                      outgoing: _messages[i].outgoing,
                      author: _messages[i].outgoing ? 'You' : 'Sofia',
                      child: Text(_messages[i].text),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FInputGroup(
              trailing: FButton(
                onPressed: _send,
                variant: FButtonVariant.ghost,
                size: FButtonSize.icon,
                tooltip: 'Send message',
                child: const Icon(Icons.arrow_upward),
              ),
              child: FInput(
                controller: _input,
                placeholder: 'Write a message…',
                semanticLabel: 'Message',
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(height: 12),
            FButton(
              onPressed: () => setState(
                () => _messages.add((
                  text:
                      'Here is another update from the team. Scroll up to read earlier messages.',
                  outgoing: false,
                )),
              ),
              variant: FButtonVariant.outline,
              size: FButtonSize.small,
              child: const Text('Simulate incoming message'),
            ),
          ],
        ),
      ),
      DemoCard(
        title: 'Attachment',
        description: 'File previews, upload status, and removal actions.',
        code:
            "FAttachment(\n  name: 'brand-guidelines.pdf',\n  description: 'PDF · 2.4 MB',\n  onPressed: openFile,\n  onRemove: removeFile,\n)",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_attachment)
              FAttachment(
                name: 'brand-guidelines.pdf',
                description: 'PDF · 2.4 MB',
                onPressed: () =>
                    showFToast(context, title: 'File preview opened'),
                onRemove: () => setState(() => _attachment = false),
              )
            else
              FButton(
                onPressed: () => setState(() => _attachment = true),
                variant: FButtonVariant.outline,
                child: const Text('Restore attachment'),
              ),
            const SizedBox(height: 12),
            FAttachment(
              name: 'project-assets.zip',
              status: _progress >= 1
                  ? FAttachmentStatus.ready
                  : FAttachmentStatus.uploading,
              description: 'Upload complete',
              progress: _progress,
            ),
            FSlider(
              value: _progress,
              min: 0,
              max: 1,
              label: 'Upload progress',
              onChanged: (value) => setState(() => _progress = value),
            ),
            const FAttachment(
              name: 'screenshot.png',
              status: FAttachmentStatus.error,
            ),
          ],
        ),
      ),
      const DemoCard(
        title: 'Bubble',
        description: 'Incoming, outgoing, and plain message surfaces.',
        code:
            "const FBubble(\n  variant: FBubbleVariant.outgoing,\n  child: Text('Looks good to me.'),\n)",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FBubble(
                child: Text('A good idea starts with a conversation.'),
              ),
            ),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FBubble(
                variant: FBubbleVariant.outgoing,
                child: Text('Let’s build something.'),
              ),
            ),
            SizedBox(height: 16),
            FBubble(
              variant: FBubbleVariant.plain,
              child: Text('Today · A fresh start', textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    ],
  );
}
