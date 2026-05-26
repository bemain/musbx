// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  // 1. Setup paths relative to the script location
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final projectDir = scriptDir.parent;

  final iconsDir = p.join(projectDir.path, 'assets', 'icons');
  final fontsDir = p.join(projectDir.path, 'assets', 'fonts');
  const fontName = 'CustomIcons';

  final outputJson = p.join(fontsDir, '$fontName.json');
  final outputTtf = p.join(fontsDir, '$fontName.ttf');
  final dartClassPath = p.join(
    projectDir.path,
    'lib',
    'widgets',
    'custom_icons.dart',
  );
  final dartClassName = fontName;

  // 2. Run Fantasticon to generate font and mapping
  print('Generating font and mapping with Fantasticon...');

  // Use runInShell: true to ensure 'npx' is found in the system path
  final result = Process.runSync('npx', [
    'fantasticon',
    iconsDir,
    '--output',
    fontsDir,
    '--name',
    fontName,
    '--font-types',
    'ttf',
    '--asset-types',
    'json',
  ], runInShell: true);

  if (result.exitCode != 0) {
    print('Error running fantasticon:\n${result.stderr}');
    exit(1);
  }

  if (result.stdout.toString().trim().isNotEmpty) {
    print(result.stdout);
  }

  // 3. Read mapping and generate Dart class
  print('Generating Dart icon class...');
  final mappingFile = File(outputJson);

  if (!mappingFile.existsSync()) {
    print('Error: Expected mapping file not found at $outputJson');
    exit(1);
  }

  final mappingString = mappingFile.readAsStringSync();
  final Map<String, dynamic> mapping =
      jsonDecode(mappingString) as Map<String, dynamic>;

  final dartHeader =
      '''// ignore_for_file: constant_identifier_names

import 'package:flutter/widgets.dart';

class $dartClassName {
  $dartClassName._();

''';

  final StringBuffer dartIcons = StringBuffer();

  mapping.forEach((iconName, codepoint) {
    final dartName = _toSnakeCase(iconName);
    // Fantasticon JSON usually outputs integers for codepoints
    final hex = (codepoint as int).toRadixString(16);
    dartIcons.writeln(
      "  static const $dartName = IconData(0x$hex, fontFamily: '$fontName', fontPackage: null);",
    );
  });

  const dartFooter = '}\n';

  // Ensure the output directory exists before writing
  final dartClassFile = File(dartClassPath);
  if (!dartClassFile.parent.existsSync()) {
    dartClassFile.parent.createSync(recursive: true);
  }

  dartClassFile.writeAsStringSync(
    dartHeader + dartIcons.toString() + dartFooter,
  );

  print('Done!');
  print('\nFont file: $outputTtf\nDart class: $dartClassPath');
}

/// Converts a kebab/space/mixed name to snake_case suitable for Dart identifiers
String _toSnakeCase(String name) {
  // Strip weird chars but keep dashes, underscores, and spaces
  var s = name.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '');

  // Replace dashes, multiple underscores, or spaces with a single underscore
  s = s.replaceAll(RegExp(r'[\- _]+'), '_');

  // Make everything lowercase
  s = s.toLowerCase();

  // Prefix leading digits with an underscore (Dart variables can't start with numbers)
  s = s.replaceAllMapped(RegExp(r'^(\d)'), (match) {
    return '_${match.group(1)}';
  });

  // Remove leading or trailing underscores if they ended up there
  s = s.replaceAll(RegExp(r'^_+|_+$'), '');

  return s;
}
