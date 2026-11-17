import 'dart:io';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final projectRoot = Directory.current.path;
  final pubspecFile = File(p.join(projectRoot, 'pubspec.yaml'));

  if (!pubspecFile.existsSync()) {
    stderr.writeln('❌ Error: pubspec.yaml not found in current directory: $projectRoot');
    exit(1);
  }

  // 1. Read package name from pubspec.yaml
  final pubspecContent = pubspecFile.readAsStringSync();
  final nameMatch = RegExp(r'^name:\s*([a-zA-Z0-9_-]+)', multiLine: true).firstMatch(pubspecContent);
  if (nameMatch == null) {
    stderr.writeln('❌ Error: Could not determine package name from pubspec.yaml');
    exit(1);
  }

  final packageName = nameMatch.group(1)!.trim();
  stdout.writeln('📦 Detected package name: $packageName');
  stdout.writeln('🔍 Scanning lib/ and test/ for relative imports...\n');

  final libDir = Directory(p.join(projectRoot, 'lib'));
  final testDir = Directory(p.join(projectRoot, 'test'));

  final targetDirs = [if (libDir.existsSync()) libDir, if (testDir.existsSync()) testDir];

  int totalFilesChecked = 0;
  int totalFilesModified = 0;
  int totalImportsConverted = 0;

  final importRegex = RegExp(
    r'''^(import|export)\s+(['"])([^'"]+)(['"])(\s*(?:as\s+\w+|show\s+[^;]+|hide\s+[^;]+)*\s*;.*)$''',
  );

  for (final dir in targetDirs) {
    final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      totalFilesChecked++;
      final lines = file.readAsLinesSync();
      bool fileModified = false;
      final newLines = <String>[];
      final fileDir = file.parent.path;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final match = importRegex.firstMatch(line.trim());

        if (match != null) {
          final keyword = match.group(1)!;
          final quote = match.group(2)!;
          final uri = match.group(3)!;
          final remainder = match.group(5)!;

          // Only process relative imports (not package: or dart:)
          if (!uri.startsWith('package:') && !uri.startsWith('dart:')) {
            // Resolve relative path against file's directory
            final resolvedTarget = p.normalize(p.join(fileDir, uri));

            // Check if target is inside lib/
            final relToLib = p.relative(resolvedTarget, from: libDir.path);
            String? newUri;

            if (!relToLib.startsWith('..') && !p.isAbsolute(relToLib)) {
              // Target is within lib/
              final normalizedPath = relToLib.replaceAll(r'\', '/');
              newUri = 'package:$packageName/$normalizedPath';
            } else if (file.path.startsWith(testDir.path)) {
              // File is in test/ and target is in test/
              final relToTest = p.relative(resolvedTarget, from: testDir.path);
              if (!relToTest.startsWith('..') && !p.isAbsolute(relToTest)) {
                // Keep or normalize within test
                newUri = uri; // Relative imports between tests are valid or can be kept
              }
            }

            if (newUri != null && newUri != uri) {
              final indent = line.substring(0, line.indexOf(keyword));
              final updatedLine = '$indent$keyword $quote$newUri$quote$remainder';
              newLines.add(updatedLine);
              fileModified = true;
              totalImportsConverted++;
              stdout.writeln('  [${p.basename(file.path)}] $uri -> $newUri');
              continue;
            }
          }
        }
        newLines.add(line);
      }

      if (fileModified) {
        file.writeAsStringSync('${newLines.join('\n')}\n');
        totalFilesModified++;
      }
    }
  }

  stdout.writeln('\n========================================');
  stdout.writeln('✨ Conversion Complete:');
  stdout.writeln('   Total files checked: $totalFilesChecked');
  stdout.writeln('   Files modified: $totalFilesModified');
  stdout.writeln('   Imports converted to package:: $totalImportsConverted');
  stdout.writeln('========================================\n');
}
