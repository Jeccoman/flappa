import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'source installer resolves dependencies, preserves edits, and preflights collisions',
    () async {
      final destination = await Directory.systemTemp.createTemp('flappa-cli-');
      addTearDown(() => destination.delete(recursive: true));
      Future<ProcessResult> run(List<String> args) => Process.run('dart', [
        'run',
        'bin/flappa_ui.dart',
        ...args,
        '--path',
        destination.path,
      ]);
      final init = await run(['init']);
      expect(init.exitCode, 0, reason: '${init.stderr}');
      expect(
        File('${destination.path}/src/theme/theme.dart').existsSync(),
        isTrue,
      );
      final add = await run(['add', 'overlays']);
      expect(add.exitCode, 0, reason: '${add.stderr}');
      final manifest =
          jsonDecode(
                await File('${destination.path}/.flappa.json').readAsString(),
              )
              as Map<String, dynamic>;
      expect(manifest['groups'], ['button', 'forms', 'overlays']);
      final button = File('${destination.path}/src/components/button.dart');
      await button.writeAsString(
        '// Local customization\n',
        mode: FileMode.append,
      );
      final theme = File('${destination.path}/src/theme/theme.dart');
      await theme.writeAsString('// Custom theme\n', mode: FileMode.append);
      final rejected = await run(['add', 'all']);
      expect(rejected.exitCode, 1);
      expect('${rejected.stderr}', contains('local changes'));
      expect(
        File('${destination.path}/src/components/advanced.dart').existsSync(),
        isFalse,
      );
      expect(await button.readAsString(), contains('Local customization'));
      final forced = await run(['add', 'all', '--force']);
      expect(forced.exitCode, 0, reason: '${forced.stderr}');
      expect(
        await button.readAsString(),
        isNot(contains('Local customization')),
      );
      expect(await theme.readAsString(), contains('Custom theme'));
      final barrel = File('${destination.path}/flappa_ui.dart');
      await barrel.writeAsString('// My export\n', mode: FileMode.append);
      final modifiedBarrel = await run(['add', 'display']);
      expect(modifiedBarrel.exitCode, 1);
      expect(
        '${modifiedBarrel.stderr}',
        contains('flappa_ui.dart has local changes'),
      );
      final bad = await run(['add', 'unknown']);
      expect(bad.exitCode, 1);
      expect('${bad.stderr}', contains('Unknown group'));
    },
  );
}
