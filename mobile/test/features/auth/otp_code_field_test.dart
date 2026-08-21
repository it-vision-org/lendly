import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lendly/features/auth/presentation/widgets/otp_code_field.dart';

void main() {
  testWidgets(
    'a pasted code with spaces normalizes to digits-only and fires onCompleted once',
    (tester) async {
      String? completedValue;
      var completedCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpCodeField(
              length: 6,
              onCompleted: (value) {
                completedValue = value;
                completedCount++;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '482 193');
      await tester.pump();

      expect(completedValue, '482193');
      expect(completedCount, 1);
    },
  );

  testWidgets('does not fire onCompleted for a partial code', (tester) async {
    var completedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpCodeField(length: 6, onCompleted: (_) => completedCount++),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '482');
    await tester.pump();

    expect(completedCount, 0);
  });

  testWidgets('clear() empties the field so it can be re-entered', (
    tester,
  ) async {
    final key = GlobalKey<OtpCodeFieldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OtpCodeField(key: key, length: 6, onCompleted: (_) {}),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '482193');
    await tester.pump();
    expect(key.currentState!.code, '482193');

    key.currentState!.clear();
    await tester.pump();

    expect(key.currentState!.code, isEmpty);
  });
}
