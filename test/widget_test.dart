import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewelsetu/features/onboarding/presentation/screens/role_selection_screen.dart';

void main() {
  testWidgets('JewelSetu role selection screen loads',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RoleSelectionScreen(),
      ),
    );

    expect(find.text('Choose your role'), findsOneWidget);
    expect(find.text('Shop Owner'), findsOneWidget);
    expect(find.text('Worker'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
