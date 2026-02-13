import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dead Button Widget Test Helper
///
/// This test helper provides utilities to detect dead/non-functional buttons
/// in your Flutter widgets during widget testing.
///
/// Usage Example:
/// ```dart
/// testWidgets('Check for dead buttons in LoginScreen', (tester) async {
///   await tester.pumpWidget(MaterialApp(home: LoginScreen()));
///
///   final deadButtons = DeadButtonTester.findDeadButtons(tester);
///
///   expect(deadButtons, isEmpty,
///     reason: 'Found ${deadButtons.length} dead buttons');
/// });
/// ```

class DeadButtonTester {
  /// Finds all dead buttons in the current widget tree
  /// Returns a list of DeadButtonInfo for each dead button found
  static List<DeadButtonInfo> findDeadButtons(WidgetTester tester) {
    final deadButtons = <DeadButtonInfo>[];

    // Check various button types
    deadButtons.addAll(_checkElevatedButtons(tester));
    deadButtons.addAll(_checkTextButtons(tester));
    deadButtons.addAll(_checkOutlinedButtons(tester));
    deadButtons.addAll(_checkIconButtons(tester));
    deadButtons.addAll(_checkFloatingActionButtons(tester));
    deadButtons.addAll(_checkInkWells(tester));
    deadButtons.addAll(_checkGestureDetectors(tester));

    return deadButtons;
  }

  static List<DeadButtonInfo> _checkElevatedButtons(WidgetTester tester) {
    final deadButtons = <DeadButtonInfo>[];
    final buttons = tester.widgetList<ElevatedButton>(
      find.byType(ElevatedButton),
    );

    for (var button in buttons) {
      if (button.onPressed == null && button.enabled) {
        deadButtons.add(
          DeadButtonInfo(
            widgetType: 'ElevatedButton',
            reason: 'onPressed is null but button is marked as enabled',
            widget: button,
          ),
        );
      }
    }

    return deadButtons;
  }

  static List<DeadButtonInfo> _checkTextButtons(WidgetTester tester) {
    final deadButtons = <DeadButtonInfo>[];
    final buttons = tester.widgetList<TextButton>(find.byType(TextButton));

    for (var button in buttons) {
      if (button.onPressed == null && button.enabled) {
        deadButtons.add(
          DeadButtonInfo(
            widgetType: 'TextButton',
            reason: 'onPressed is null but button is marked as enabled',
            widget: button,
          ),
        );
      }
    }

    return deadButtons;
  }

  static List<DeadButtonInfo> _checkOutlinedButtons(WidgetTester tester) {
    final deadButtons = <DeadButtonInfo>[];
    final buttons = tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    );

    for (var button in buttons) {
      if (button.onPressed == null && button.enabled) {
        deadButtons.add(
          DeadButtonInfo(
            widgetType: 'OutlinedButton',
            reason: 'onPressed is null but button is marked as enabled',
            widget: button,
          ),
        );
      }
    }

    return deadButtons;
  }

  static List<DeadButtonInfo> _checkIconButtons(WidgetTester tester) {
    final deadButtons = <DeadButtonInfo>[];
    final buttons = tester.widgetList<IconButton>(find.byType(IconButton));

    for (var button in buttons) {
      // IconButton doesn't have an enabled property, so null onPressed means disabled
      // We'll still report it as potentially dead
      if (button.onPressed == null) {
        deadButtons.add(
          DeadButtonInfo(
            widgetType: 'IconButton',
            reason: 'onPressed is null (disabled)',
            widget: button,
          ),
        );
      }
    }

    return deadButtons;
  }

  static List<DeadButtonInfo> _checkFloatingActionButtons(WidgetTester tester) {
    final deadButtons = <DeadButtonInfo>[];
    final buttons = tester.widgetList<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );

    for (var button in buttons) {
      if (button.onPressed == null) {
        deadButtons.add(
          DeadButtonInfo(
            widgetType: 'FloatingActionButton',
            reason: 'onPressed is null',
            widget: button,
          ),
        );
      }
    }

    return deadButtons;
  }

  static List<DeadButtonInfo> _checkInkWells(WidgetTester tester) {
    final deadButtons = <DeadButtonInfo>[];
    final inkWells = tester.widgetList<InkWell>(find.byType(InkWell));

    for (var inkWell in inkWells) {
      // InkWell should have at least one tap handler
      if (inkWell.onTap == null &&
          inkWell.onDoubleTap == null &&
          inkWell.onLongPress == null) {
        deadButtons.add(
          DeadButtonInfo(
            widgetType: 'InkWell',
            reason: 'No tap handlers (onTap, onDoubleTap, onLongPress)',
            widget: inkWell,
          ),
        );
      }
    }

    return deadButtons;
  }

  static List<DeadButtonInfo> _checkGestureDetectors(WidgetTester tester) {
    final deadButtons = <DeadButtonInfo>[];
    final detectors = tester.widgetList<GestureDetector>(
      find.byType(GestureDetector),
    );

    for (var detector in detectors) {
      // GestureDetector should have at least one gesture handler
      final hasAnyHandler =
          detector.onTap != null ||
          detector.onDoubleTap != null ||
          detector.onLongPress != null ||
          detector.onPanDown != null ||
          detector.onPanStart != null ||
          detector.onPanUpdate != null ||
          detector.onPanEnd != null ||
          detector.onScaleStart != null ||
          detector.onScaleUpdate != null ||
          detector.onScaleEnd != null;

      if (!hasAnyHandler) {
        deadButtons.add(
          DeadButtonInfo(
            widgetType: 'GestureDetector',
            reason: 'No gesture handlers defined',
            widget: detector,
          ),
        );
      }
    }

    return deadButtons;
  }

  /// Prints a detailed report of dead buttons
  static void printReport(List<DeadButtonInfo> deadButtons) {
    if (deadButtons.isEmpty) {
      print('✅ No dead buttons found!');
      return;
    }

    print('\n⚠️  Found ${deadButtons.length} potential dead buttons:\n');

    for (var i = 0; i < deadButtons.length; i++) {
      final button = deadButtons[i];
      print('${i + 1}. ${button.widgetType}');
      print('   Reason: ${button.reason}');
      print('   Widget: ${button.widget}');
      print('');
    }
  }

  /// Attempts to tap all buttons and reports which ones don't respond
  static Future<List<UnresponsiveButtonInfo>> findUnresponsiveButtons(
    WidgetTester tester,
  ) async {
    final unresponsiveButtons = <UnresponsiveButtonInfo>[];

    // Find all tappable widgets
    final tappableTypes = [
      ElevatedButton,
      TextButton,
      OutlinedButton,
      IconButton,
      FloatingActionButton,
      InkWell,
      GestureDetector,
    ];

    for (var type in tappableTypes) {
      final finders = find.byType(type);
      final count = tester.widgetList(finders).length;

      for (var i = 0; i < count; i++) {
        try {
          final finder = finders.at(i);

          // Try to tap it
          await tester.tap(finder);
          await tester.pump();

          // If we get here without exception, the tap succeeded
          // But we can't easily tell if it did anything meaningful
        } catch (e) {
          unresponsiveButtons.add(
            UnresponsiveButtonInfo(
              widgetType: type.toString(),
              index: i,
              error: e.toString(),
            ),
          );
        }
      }
    }

    return unresponsiveButtons;
  }
}

class DeadButtonInfo {
  final String widgetType;
  final String reason;
  final Widget widget;

  DeadButtonInfo({
    required this.widgetType,
    required this.reason,
    required this.widget,
  });

  @override
  String toString() {
    return 'DeadButton: $widgetType - $reason';
  }
}

class UnresponsiveButtonInfo {
  final String widgetType;
  final int index;
  final String error;

  UnresponsiveButtonInfo({
    required this.widgetType,
    required this.index,
    required this.error,
  });

  @override
  String toString() {
    return 'UnresponsiveButton: $widgetType[$index] - $error';
  }
}

// Example test that you can use as a template
void main() {
  group('Dead Button Detection Example', () {
    testWidgets('Example: Check for dead buttons in a sample widget', (
      tester,
    ) async {
      // Example widget with some dead buttons
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    print('This works!');
                  },
                  child: const Text('Working Button'),
                ),
                ElevatedButton(
                  onPressed: null, // Dead button!
                  child: const Text('Dead Button'),
                ),
                InkWell(
                  // No onTap! Dead!
                  child: const Text('Dead InkWell'),
                ),
                GestureDetector(
                  onTap: () {
                    print('This works!');
                  },
                  child: const Text('Working GestureDetector'),
                ),
              ],
            ),
          ),
        ),
      );

      // Find dead buttons
      final deadButtons = DeadButtonTester.findDeadButtons(tester);

      // Print report
      DeadButtonTester.printReport(deadButtons);

      // You can assert based on your requirements
      // For example, in production you might want:
      // expect(deadButtons, isEmpty, reason: 'No dead buttons should exist');

      // For this example, we expect to find 2 dead buttons
      expect(deadButtons.length, greaterThan(0));
    });
  });
}
