
import 'package:flutter_test/flutter_test.dart';
import 'package:jewelsetu/app.dart';

void main() {
  testWidgets('JewelSetu role selection screen loads',
          (WidgetTester tester) async {
        await tester.pumpWidget(const JewelSetuApp());

        expect(find.text('JewelSetu'), findsOneWidget);
        expect(find.text('Welcome!'), findsOneWidget);
        expect(find.text('Shop Owner'), findsOneWidget);
        expect(find.text('Worker'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      });
}
