import 'package:flutter_test/flutter_test.dart';
import 'package:scan_to_know/main.dart';

void main() {
  testWidgets('ScanToKnow app starts', (tester) async {
    await tester.pumpWidget(const ScanToKnowApp());
    expect(find.byType(ScanToKnowApp), findsOneWidget);
  });
}
