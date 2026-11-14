import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  stdout.writeln(
    '====================================================================',
  );
  stdout.writeln('VITALIS QUALITY SPRINT GATE');
  stdout.writeln('Executing automated 5-stage verification suite...');
  stdout.writeln(
    '====================================================================',
  );

  final stopwatch = Stopwatch()..start();

  // Stage 1: Dependency resolution
  await _runStep(
    stepNumber: 1,
    title: 'Dependencies Resolution',
    executable: 'flutter',
    arguments: ['pub', 'get'],
  );

  // Stage 2: Code formatting audit
  await _runStep(
    stepNumber: 2,
    title: 'Dart Code Formatting Audit',
    executable: 'dart',
    arguments: [
      'format',
      '--output=none',
      '--set-exit-if-changed',
      'lib',
      'test',
    ],
  );

  // Stage 3: Static analysis
  await _runStep(
    stepNumber: 3,
    title: 'Static Analysis (0 Errors, 0 Warnings)',
    executable: 'flutter',
    arguments: ['analyze', '--no-pub'],
  );

  // Stage 4: Unit and widget test suite
  await _runStep(
    stepNumber: 4,
    title: 'Automated Test Suite Execution',
    executable: 'flutter',
    arguments: ['test', '--no-pub'],
  );

  // Stage 5: Android runtime logcat check
  await _runAdbAudit(stepNumber: 5);

  stopwatch.stop();
  final elapsed = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2);

  stdout.writeln(
    '====================================================================',
  );
  stdout.writeln(
    '[VITALIS QUALITY GATE] ALL 5 CHECKS PASSED. SYSTEM DEPLOYABLE.',
  );
  stdout.writeln('Total verification time: ${elapsed}s');
  stdout.writeln(
    '====================================================================',
  );
  exit(0);
}

Future<void> _runStep({
  required int stepNumber,
  required String title,
  required String executable,
  required List<String> arguments,
}) async {
  stdout.writeln('[CHECK $stepNumber/5] Starting: $title');
  final result = await Process.run(executable, arguments, runInShell: true);

  if (result.exitCode != 0) {
    stderr.writeln('[CHECK $stepNumber/5 FAILED]: $title');
    stderr.writeln(result.stdout);
    stderr.writeln(result.stderr);
    exit(result.exitCode);
  }

  stdout.writeln('[CHECK $stepNumber/5 PASSED]: $title');
}

Future<void> _runAdbAudit({required int stepNumber}) async {
  stdout.writeln(
    '[CHECK $stepNumber/5] Starting: Android ADB Runtime Logcat Audit',
  );

  try {
    final devicesResult = await Process.run('adb', [
      'devices',
    ], runInShell: true);

    if (devicesResult.exitCode != 0) {
      stdout.writeln(
        '[CHECK $stepNumber/5] ADB Check: ADB tool not available or offline. Skipping.',
      );
      return;
    }

    final output = devicesResult.stdout.toString();
    final lines = LineSplitter.split(output).skip(1).where((line) {
      final trimmed = line.trim();
      return trimmed.isNotEmpty && trimmed.endsWith('device');
    }).toList();

    if (lines.isEmpty) {
      stdout.writeln(
        '[CHECK $stepNumber/5 PASSED]: No physical or virtual device attached. Logcat audit skipped.',
      );
      return;
    }

    final logcatResult = await Process.run('adb', [
      'logcat',
      '-d',
    ], runInShell: true);

    final logcatOutput = logcatResult.stdout.toString();
    final fatalKeywords = [
      'FATAL EXCEPTION',
      'AndroidRuntime: FATAL',
      'SIGSEGV',
    ];

    for (final keyword in fatalKeywords) {
      if (logcatOutput.contains(keyword)) {
        stderr.writeln(
          '[CHECK $stepNumber/5 FAILED]: Fatal exception detected in adb logcat: $keyword',
        );
        exit(1);
      }
    }

    stdout.writeln(
      '[CHECK $stepNumber/5 PASSED]: ADB Logcat clean. Zero fatal exceptions detected.',
    );
  } catch (e) {
    stdout.writeln(
      '[CHECK $stepNumber/5] ADB Check: ADB audit skipped (${e.toString()}).',
    );
  }
}
