#!/usr/bin/env dart

/// Improved Dead Button Analyzer v2.0
/// This version filters out common false positives like theme definitions

import 'dart:io';

void main() {
  print('🔍 Dead Button Analyzer v2.0 for Flutter\n');
  print('Scanning for buttons without functional handlers...\n');

  final libDirectory = Directory('lib');

  if (!libDirectory.existsSync()) {
    print('❌ Error: lib directory not found!');
    exit(1);
  }

  final analyzer = ImprovedDeadButtonAnalyzer();
  analyzer.scanDirectory(libDirectory);
  analyzer.printReport();
}

class ImprovedDeadButtonAnalyzer {
  final List<DeadButtonIssue> issues = [];
  final List<DeadButtonIssue> falsePositives = [];
  int filesScanned = 0;
  int totalButtons = 0;

  // Button widgets to look for
  final buttonPatterns = [
    'ElevatedButton',
    'TextButton',
    'OutlinedButton',
    'IconButton',
    'FloatingActionButton',
    'InkWell',
    'GestureDetector',
    'MaterialButton',
    'CupertinoButton',
  ];

  // Files to skip (known to contain style definitions only)
  final filesToSkip = ['app_theme.dart', 'theme.dart', 'styles.dart'];

  void scanDirectory(Directory dir) {
    final files = dir.listSync(recursive: true);

    for (var entity in files) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // Skip theme files
        final fileName = entity.path.split('/').last;
        if (filesToSkip.contains(fileName)) {
          continue;
        }
        scanFile(entity);
      }
    }
  }

  void scanFile(File file) {
    filesScanned++;
    final content = file.readAsStringSync();
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      // Check for each button pattern
      for (var buttonType in buttonPatterns) {
        if (line.contains(buttonType)) {
          totalButtons++;
          _analyzeButton(file, lineNumber, lines, i, buttonType);
        }
      }
    }
  }

  void _analyzeButton(
    File file,
    int lineNumber,
    List<String> lines,
    int lineIndex,
    String buttonType,
  ) {
    // Get the button code block
    final buttonCode = _extractButtonCode(lines, lineIndex);

    // Check if this is in a theme definition (false positive)
    if (_isInThemeDefinition(lines, lineIndex)) {
      falsePositives.add(
        DeadButtonIssue(
          file: file.path,
          lineNumber: lineNumber,
          buttonType: buttonType,
          issueType: 'Theme definition (not a real button)',
          codeSnippet: buttonCode,
        ),
      );
      return;
    }

    // Check for dead button patterns
    final issue = _checkForDeadButton(buttonCode, buttonType);

    if (issue != null) {
      issues.add(
        DeadButtonIssue(
          file: file.path,
          lineNumber: lineNumber,
          buttonType: buttonType,
          issueType: issue,
          codeSnippet: buttonCode,
        ),
      );
    }
  }

  bool _isInThemeDefinition(List<String> lines, int lineIndex) {
    // Look at surrounding context (10 lines before)
    final start = (lineIndex - 10).clamp(0, lines.length);
    final contextLines = lines.sublist(start, lineIndex + 1);
    final context = contextLines.join('\n').toLowerCase();

    // Check for theme-related keywords
    return context.contains('theme:') ||
        context.contains('themedata') ||
        context.contains('buttontheme') ||
        context.contains('elevatedbuttontheme') ||
        context.contains('textbuttontheme') ||
        context.contains('outlinedbuttontheme');
  }

  String _extractButtonCode(List<String> lines, int startIndex) {
    final buffer = StringBuffer();
    int parenthesisCount = 0;
    bool started = false;

    for (int i = startIndex; i < lines.length && i < startIndex + 30; i++) {
      final line = lines[i];
      buffer.writeln(line);

      for (var char in line.runes) {
        final c = String.fromCharCode(char);
        if (c == '(') {
          parenthesisCount++;
          started = true;
        } else if (c == ')') {
          parenthesisCount--;
        }
      }

      if (started && parenthesisCount <= 0) {
        break;
      }
    }

    return buffer.toString();
  }

  String? _checkForDeadButton(String buttonCode, String buttonType) {
    final cleanCode = buttonCode.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

    // Check for InkWell and GestureDetector specifically
    if (buttonType == 'InkWell' || buttonType == 'GestureDetector') {
      // Check for ANY gesture handler
      final hasAnyGestureHandler =
          cleanCode.contains('ontap') ||
          cleanCode.contains('ondoubletap') ||
          cleanCode.contains('onlongpress') ||
          cleanCode.contains('onpandown') ||
          cleanCode.contains('onpanupdate') ||
          cleanCode.contains('onpanend') ||
          cleanCode.contains('onhorizontaldrag') ||
          cleanCode.contains('onverticaldrag') ||
          cleanCode.contains('onscale');

      if (!hasAnyGestureHandler) {
        return 'No gesture handlers found';
      }

      // Check for null handlers
      if (cleanCode.contains('ontap: null') ||
          cleanCode.contains('ontap:null')) {
        return 'onTap is explicitly set to null';
      }

      return null;
    }

    // For button widgets, check for onPressed
    if (!cleanCode.contains('onpressed')) {
      return 'No onPressed handler found';
    }

    // Check for null onPressed
    if (cleanCode.contains('onpressed: null') ||
        cleanCode.contains('onpressed:null')) {
      return 'onPressed is explicitly set to null (disabled button)';
    }

    // Check for empty function
    if (cleanCode.contains('onpressed: () {}') ||
        cleanCode.contains('onpressed:() {}') ||
        cleanCode.contains('onpressed: (){}') ||
        cleanCode.contains('onpressed:(){}')) {
      return 'onPressed has empty function (no action)';
    }

    return null;
  }

  void printReport() {
    print('\n${'=' * 80}');
    print('📊 SCAN REPORT');
    print('=' * 80);
    print('Files scanned: $filesScanned');
    print('Total buttons found: $totalButtons');
    print('False positives filtered: ${falsePositives.length}');
    print('Real dead buttons found: ${issues.length}');
    print('=' * 80);

    if (issues.isEmpty) {
      print('\n✅ Great! No dead buttons detected in your codebase.');
      print('   All buttons appear to have functional handlers.\n');
      return;
    }

    print('\n⚠️  Dead buttons detected:\n');

    // Group by file for better readability
    final groupedByFile = <String, List<DeadButtonIssue>>{};
    for (var issue in issues) {
      // Shorten file path for readability
      final shortPath = issue.file.replaceAll('lib/', '');
      groupedByFile.putIfAbsent(shortPath, () => []).add(issue);
    }

    int issueNumber = 1;
    groupedByFile.forEach((file, fileIssues) {
      print('━' * 80);
      print('📁 File: $file');
      print('   Issues: ${fileIssues.length}');
      print('━' * 80);

      for (var issue in fileIssues) {
        print('\n$issueNumber. ${issue.buttonType} (Line ${issue.lineNumber})');
        print('   ❌ ${issue.issueType}');
        print('');
        issueNumber++;
      }
    });

    _printPrioritizedRecommendations(groupedByFile);
  }

  void _printPrioritizedRecommendations(
    Map<String, List<DeadButtonIssue>> groupedByFile,
  ) {
    print('\n${'=' * 80}');
    print('🎯 PRIORITIZED ACTION ITEMS');
    print('=' * 80);

    // Identify critical files
    final criticalScreens = [
      'login_screen.dart',
      'register_screen.dart',
      'checkout_screen.dart',
      'payment',
      'cart',
      'order_confirmation',
    ];

    final highPriority = <String, List<DeadButtonIssue>>{};
    final mediumPriority = <String, List<DeadButtonIssue>>{};
    final lowPriority = <String, List<DeadButtonIssue>>{};

    groupedByFile.forEach((file, issues) {
      if (criticalScreens.any((screen) => file.contains(screen))) {
        highPriority[file] = issues;
      } else if (file.contains('screen')) {
        mediumPriority[file] = issues;
      } else {
        lowPriority[file] = issues;
      }
    });

    if (highPriority.isNotEmpty) {
      print('\n🔴 HIGH PRIORITY (Critical screens - Fix ASAP):');
      highPriority.forEach((file, issues) {
        print('   • $file (${issues.length} issues)');
      });
    }

    if (mediumPriority.isNotEmpty) {
      print('\n🟡 MEDIUM PRIORITY (Other screens - Review soon):');
      mediumPriority.forEach((file, issues) {
        print('   • $file (${issues.length} issues)');
      });
    }

    if (lowPriority.isNotEmpty) {
      print(
        '\n🟢 LOW PRIORITY (Widgets/Components - Review when time permits):',
      );
      lowPriority.forEach((file, issues) {
        print('   • $file (${issues.length} issues)');
      });
    }

    print('\n${'=' * 80}');
    print('💡 NEXT STEPS:');
    print('=' * 80);
    print('1. Start with HIGH PRIORITY files');
    print('2. Open each file and go to the line numbers mentioned');
    print('3. For each button, decide:');
    print('   • Add missing onPressed/onTap handler');
    print('   • Remove button if not needed');
    print('   • Add comment if intentionally disabled');
    print('=' * 80 + '\n');
  }
}

class DeadButtonIssue {
  final String file;
  final int lineNumber;
  final String buttonType;
  final String issueType;
  final String codeSnippet;

  DeadButtonIssue({
    required this.file,
    required this.lineNumber,
    required this.buttonType,
    required this.issueType,
    required this.codeSnippet,
  });
}
