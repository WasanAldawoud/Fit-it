# AI Chat Frontend Tests

This directory contains automated tests for the AI chat frontend components.

## Setup

The tests use Flutter's built-in testing framework. No additional dependencies required beyond what's in `pubspec.yaml`.

## Running Tests

### Run all tests:
```bash
flutter test
```

### Run with coverage:
```bash
flutter test --coverage
```

### Run specific test file:
```bash
flutter test ai_chat_test.dart
```

### Run tests with verbose output:
```bash
flutter test -v
```

## Test Structure

### ai_chat_test.dart
- **ChatMessage Tests**: Tests for message creation, types, and properties
- **MessageType Tests**: Tests for enum values
- **ChatScreen Widget Tests**: Tests for UI components and interactions
- **UI Component Tests**: Tests for styling and visual elements
- **Integration Flow Tests**: Tests for complete UI workflows

## Test Coverage

The tests cover:
- ✅ Message creation and type handling
- ✅ Widget rendering and interactions
- ✅ UI styling and visual feedback
- ✅ State-dependent behavior
- ✅ Message flow simulation
- ✅ Component integration

## Widget Testing Best Practices

### Finding Widgets:
```dart
// Find by text
expect(find.text('Hello'), findsOneWidget);

// Find by type
expect(find.byType(ElevatedButton), findsNWidgets(2));

// Find by icon
expect(find.byIcon(Icons.check_circle), findsOneWidget);

// Find by key (recommended for complex widgets)
expect(find.byKey(const Key('approve_button')), findsOneWidget);
```

### Testing Interactions:
```dart
// Tap a button
await tester.tap(find.text('Approve'));
await tester.pump(); // Rebuild the widget tree

// Enter text
await tester.enterText(find.byType(TextField), 'Hello AI');
await tester.pump();

// Wait for async operations
await tester.pumpAndSettle();
```

### Testing Styling:
```dart
// Check button color
final button = find.byType(ElevatedButton).evaluate().first.widget as ElevatedButton;
expect(button.style?.backgroundColor?.resolve({}), Colors.green);
```

## Adding New Tests

When adding new UI components or features:

1. Add unit tests for new widgets
2. Add integration tests for user flows
3. Test different screen sizes (use `tester.binding.window`)
4. Test accessibility features
5. Update existing tests if UI changes

## CI/CD Integration

Add to your CI/CD pipeline:

```yaml
# Example GitHub Actions
- name: Run Frontend Tests
  run: |
    cd frontendscreen
    flutter test --coverage
```

## Common Testing Patterns

### Testing State Changes:
```dart
testWidgets('button changes state on tap', (WidgetTester tester) async {
  bool isPressed = false;

  await tester.pumpWidget(
    MaterialApp(
      home: ElevatedButton(
        onPressed: () => isPressed = true,
        child: const Text('Press me'),
      ),
    ),
  );

  await tester.tap(find.byType(ElevatedButton));
  expect(isPressed, true);
});
```

### Testing Async Operations:
```dart
testWidgets('shows loading then result', (WidgetTester tester) async {
  await tester.pumpWidget(MyAsyncWidget());

  // Initially shows loading
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Wait for async operation
  await tester.pumpAndSettle();

  // Now shows result
  expect(find.text('Result loaded'), findsOneWidget);
});
```

## Mocking (Advanced)

For HTTP requests or complex dependencies, consider using `mockito`:

```yaml
# Add to pubspec.yaml
dev_dependencies:
  mockito: ^5.4.4
  build_runner: ^2.4.6
```

Then create mocks:
```dart
@GenerateMocks([http.Client])
import 'mocks.mocks.dart';
```

## Troubleshooting

### Common Issues:
1. **Widget not found**: Check widget tree structure and keys
2. **Test timing out**: Use `pumpAndSettle()` for async operations
3. **Platform-specific code**: Use `debugDefaultTargetPlatformOverride`
4. **Animation issues**: Disable animations with `timeDilation = 1.0`

### Debug Tips:
- Use `debugDumpApp()` to see widget tree
- Add `print` statements in widget code
- Use `tester.takeException()` to catch errors

## Performance Testing

For performance-sensitive components:
```dart
testWidgets('renders quickly', (WidgetTester tester) async {
  final stopwatch = Stopwatch()..start();

  await tester.pumpWidget(MyWidget());

  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(100));
});
```

## Accessibility Testing

Test accessibility features:
```dart
testWidgets('has proper semantics', (WidgetTester tester) async {
  await tester.pumpWidget(MyWidget());

  final semantics = tester.getSemantics(find.byType(MyWidget));
  expect(semantics.label, 'Expected label');
  expect(semantics.hasFlag(SemanticsFlag.isButton), true);
});
