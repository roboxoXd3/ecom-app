#!/usr/bin/env dart

/// Dead Button Analyzer
/// This script scans your Flutter project for buttons that have no onPressed/onTap handlers
/// or have null/disabled handlers, which makes them "dead" (non-functional).
///
/// Usage: dart dead_button_analyzer.dart
///
/// This will scan the lib/ directory and report all potentially dead buttons.

import 'dart:io';

void main() {
  print('🔍 Dead Button Analyzer for Flutter\n');
  print('Scanning for buttons without functional handlers...\n');

  final libDirectory = Directory('lib');

  if (!libDirectory.existsSync()) {
    print('❌ Error: lib directory not found!');
    exit(1);
  }

  final analyzer = DeadButtonAnalyzer();
  analyzer.scanDirectory(libDirectory);
  analyzer.printReport();
}

class DeadButtonAnalyzer {
  final List<DeadButtonIssue> issues = [];
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
    'RaisedButton', // Deprecated but might exist
    'FlatButton', // Deprecated but might exist
    'CupertinoButton',
  ];

  void scanDirectory(Directory dir) {
    final files = dir.listSync(recursive: true);

    for (var entity in files) {
      if (entity is File && entity.path.endsWith('.dart')) {
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
          _analyzeButton(file, lineNumber, lines, i, buttonType, content);
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
    String fullContent,
  ) {
    // Get the button code block (next ~20 lines or until closing parenthesis)
    final buttonCode = _extractButtonCode(lines, lineIndex);

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

      // If we've closed all parentheses after starting, we're done
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
      // These need onTap, onDoubleTap, onLongPress, etc.
      if (!cleanCode.contains('ontap') &&
          !cleanCode.contains('ondoubletap') &&
          !cleanCode.contains('onlongpress') &&
          !cleanCode.contains('onpandown') &&
          !cleanCode.contains('onpanupdate')) {
        return 'No tap handler found (onTap, onDoubleTap, onLongPress, etc.)';
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
    print('Dead buttons found: ${issues.length}');
    print('=' * 80);

    if (issues.isEmpty) {
      print('\n✅ Great! No dead buttons detected in your codebase.');
      print('   All buttons appear to have functional handlers.\n');
      return;
    }

    print('\n⚠️  Dead buttons detected:\n');

    // Group by issue type
    final groupedIssues = <String, List<DeadButtonIssue>>{};
    for (var issue in issues) {
      groupedIssues.putIfAbsent(issue.issueType, () => []).add(issue);
    }

    int issueNumber = 1;
    groupedIssues.forEach((issueType, issueList) {
      print('━' * 80);
      print('Issue Type: $issueType');
      print('Count: ${issueList.length}');
      print('━' * 80);

      for (var issue in issueList) {
        print('\n$issueNumber. ${issue.buttonType}');
        print('   📁 File: ${issue.file}');
        print('   📍 Line: ${issue.lineNumber}');
        print('   ❌ Issue: ${issue.issueType}');
        print('\n   Code Preview:');
        final preview = issue.codeSnippet.split('\n').take(5).join('\n');
        preview.split('\n').forEach((line) {
          print('      $line');
        });
        print('');
        issueNumber++;
      }
    });

    print('\n${'=' * 80}');
    print('💡 RECOMMENDATIONS:');
    print('=' * 80);
    print('1. Review each dead button to determine if it should:');
    print('   • Have an onPressed/onTap handler added');
    print('   • Be removed from the UI if not needed');
    print('   • Be intentionally disabled (null is fine for disabled state)');
    print('');
    print('2. For intentionally disabled buttons:');
    print('   • Use null for onPressed when button should be disabled');
    print(
      '   • Consider using a variable: onPressed: isEnabled ? () {} : null',
    );
    print('');
    print('3. For GestureDetector/InkWell without handlers:');
    print('   • These might be used for styling only (not interactive)');
    print(
      '   • Consider using Container or other non-interactive widgets instead',
    );
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
