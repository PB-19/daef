import 'package:flutter_test/flutter_test.dart';
import 'package:daef/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DaefApp());
    expect(find.text('DAEF'), findsOneWidget);
  });
}
