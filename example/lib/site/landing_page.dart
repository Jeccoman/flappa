import 'package:flappa_ui/flappa_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'site_widgets.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({
    super.key,
    required this.onComponents,
    required this.onPlayground,
  });
  final VoidCallback onComponents, onPlayground;
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Widget _eyebrow(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.8,
      color: Color(0xFF087F5B),
    ),
  );
  Widget _heading(String text, {double size = 44}) => Text(
    text,
    style: TextStyle(
      fontSize: size,
      height: 1.08,
      letterSpacing: -size / 23,
      fontWeight: FontWeight.w700,
    ),
  );
  Widget _body(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 15,
      height: 1.7,
      color: FTheme.of(context).colors.mutedForeground,
    ),
  );

  Widget _feature(
    IconData icon,
    String number,
    String title,
    String description,
  ) => FCard(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24),
            const Spacer(),
            Text(
              number,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                color: FTheme.of(context).colors.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 12),
        _body(description),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 1000;
          final pagePadding = narrow ? 20.0 : 48.0;
          return Column(
            children: [
              Container(
                height: 76,
                padding: EdgeInsets.symmetric(horizontal: pagePadding),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: FTheme.of(context).colors.border),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      children: [
                        SiteBrand(
                          onPressed: () => _scroll.animateTo(
                            0,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                          ),
                        ),
                        const Spacer(),
                        if (!narrow) ...[
                          FButton(
                            onPressed: widget.onComponents,
                            variant: FButtonVariant.ghost,
                            child: const Text('Components'),
                          ),
                          const SizedBox(width: 12),
                          FButton(
                            onPressed: widget.onPlayground,
                            variant: FButtonVariant.ghost,
                            child: const Text('Playground'),
                          ),
                          const SizedBox(width: 28),
                        ],
                        FButton(
                          onPressed: widget.onComponents,
                          variant: FButtonVariant.outline,
                          size: narrow ? FButtonSize.small : FButtonSize.medium,
                          trailing: const Icon(Icons.arrow_outward, size: 16),
                          child: const Text('Get started'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          pagePadding,
                          narrow ? 54 : 76,
                          pagePadding,
                          0,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1140),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF8F2),
                                    border: Border.all(
                                      color: const Color(0xFFD6EADC),
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: Color(0xFF087F5B),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'FLUTTER NATIVE. OPEN SOURCE.',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.3,
                                          color: Color(0xFF087F5B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  'Less boilerplate.\nMore beautiful.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: narrow ? 48 : 82,
                                    height: 1.02,
                                    letterSpacing: narrow ? -2.5 : -4.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF132A22),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 530,
                                  ),
                                  child: Text(
                                    'Thoughtful Flutter components for your next big idea.\nPick your pieces. Make them yours. Ship something good.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: narrow ? 15 : 17,
                                      height: 1.7,
                                      color: const Color(0xFF647169),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    FButton(
                                      onPressed: widget.onPlayground,
                                      size: FButtonSize.large,
                                      trailing: const Icon(Icons.arrow_forward),
                                      child: const Text('Open playground'),
                                    ),
                                    FButton(
                                      onPressed: widget.onComponents,
                                      size: FButtonSize.large,
                                      variant: FButtonVariant.outline,
                                      child: const Text('Browse components'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Free to use. No account. Just Flutter.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: FTheme.of(
                                      context,
                                    ).colors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const PackageLink(),
                                SizedBox(height: narrow ? 40 : 54),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 36,
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: narrow ? 24 : 68,
                                    runSpacing: 16,
                                    children: [
                                      for (final (value, label) in [
                                        ('71', 'components'),
                                        ('12', 'source-copy groups'),
                                        ('MIT', 'licensed'),
                                        ('100%', 'Flutter'),
                                      ])
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              value,
                                              style: const TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -.8,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: FTheme.of(
                                                  context,
                                                ).colors.mutedForeground,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                const FSeparator(),
                                SizedBox(height: narrow ? 60 : 88),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _eyebrow(
                                    'SMALL PIECES. BIG POSSIBILITIES.',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _heading(
                                    'The details are done.\nThe possibilities are yours.',
                                    size: narrow ? 34 : 46,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                LayoutBuilder(
                                  builder: (context, box) {
                                    final cards = [
                                      _feature(
                                        Icons.widgets_outlined,
                                        '01',
                                        'A considered starting point.',
                                        'Forms, navigation, overlays, charts, and the little details that make an interface feel complete.',
                                      ),
                                      _feature(
                                        Icons.tune,
                                        '02',
                                        'Your brand, by default.',
                                        'Semantic colors, light and dark themes, and a shared radius. Make every component feel like it belongs.',
                                      ),
                                      _feature(
                                        Icons.code,
                                        '03',
                                        'Keep the source close.',
                                        'Use the package or copy the components you need. Read them, change them, and make them your own.',
                                      ),
                                    ];
                                    return narrow
                                        ? Column(
                                            children: [
                                              for (final card in cards)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 16,
                                                      ),
                                                  child: card,
                                                ),
                                            ],
                                          )
                                        : Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              for (
                                                var i = 0;
                                                i < cards.length;
                                                i++
                                              ) ...[
                                                if (i > 0)
                                                  const SizedBox(width: 16),
                                                Expanded(child: cards[i]),
                                              ],
                                            ],
                                          );
                                  },
                                ),
                                SizedBox(height: narrow ? 60 : 96),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(narrow ? 24 : 48),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF132A22),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'MEET YOUR NEW SKETCHBOOK',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 1.8,
                                          color: Color(0xFFA7DBBE),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'An idea to a screen.\nWithout the blank-file feeling.',
                                        style: TextStyle(
                                          fontSize: narrow ? 32 : 46,
                                          height: 1.1,
                                          letterSpacing: -1.7,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: 560,
                                        ),
                                        child: Text(
                                          'Start with a template, arrange your components, and tune every detail in a live canvas. When it feels right, take the Flutter code with you.',
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.7,
                                            color: Color(0xFFB9CCC0),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      Wrap(
                                        spacing: 24,
                                        runSpacing: 12,
                                        children: [
                                          for (final label in [
                                            'Arrange visually',
                                            'Tune your theme',
                                            'Export runnable Dart',
                                          ])
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_outline,
                                                  size: 15,
                                                  color: Color(0xFFA7DBBE),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  label,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 30),
                                      FilledButton(
                                        onPressed: widget.onPlayground,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFC9F4D9,
                                          ),
                                          foregroundColor: const Color(
                                            0xFF132A22,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 22,
                                            vertical: 20,
                                          ),
                                        ),
                                        child: const Text(
                                          'Build your first screen →',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: narrow ? 60 : 88),
                                _eyebrow('ONE COMMAND. A FRESH START.'),
                                const SizedBox(height: 18),
                                _heading(
                                  'Make room for the good stuff.',
                                  size: narrow ? 32 : 42,
                                ),
                                const SizedBox(height: 16),
                                _body(
                                  'Add the components. Spend your time on what makes your app yours.',
                                ),
                                const SizedBox(height: 24),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 550,
                                  ),
                                  child: FCodeBlock(
                                    code: 'flutter pub add flappa_ui',
                                    language: FCodeLanguage.bash,
                                    filename: 'Install from your Flutter app',
                                    fontFamily: 'JetBrainsMono',
                                    showLineNumbers: false,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                FButton(
                                  onPressed: widget.onComponents,
                                  variant: FButtonVariant.link,
                                  child: const Text('Explore the library →'),
                                ),
                                SizedBox(height: narrow ? 50 : 80),
                                const FSeparator(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 30,
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    spacing: 24,
                                    runSpacing: 16,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      SiteBrand(
                                        onPressed: () => _scroll.animateTo(
                                          0,
                                          duration: const Duration(
                                            milliseconds: 350,
                                          ),
                                          curve: Curves.easeOut,
                                        ),
                                      ),
                                      const Text(
                                        'Built with Flutter. Inspired by shadcn/ui.\nOpen source under the MIT license.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          height: 1.7,
                                          color: Color(0xFF647169),
                                        ),
                                      ),
                                      FButton(
                                        onPressed: () async {
                                          await Clipboard.setData(
                                            const ClipboardData(
                                              text: 'flutter pub add flappa_ui',
                                            ),
                                          );
                                          if (context.mounted) {
                                            showFToast(
                                              context,
                                              title: 'Install command copied',
                                            );
                                          }
                                        },
                                        variant: FButtonVariant.ghost,
                                        child: const Text(
                                          'Copy install command',
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
