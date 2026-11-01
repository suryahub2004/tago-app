import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mea/app.dart';

void main() {
  testWidgets('SmartVital app starts on splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartVitalApp()));
    expect(find.text('SmartVital'), findsWidgets);
    await tester.pump(const Duration(seconds: 3)); // Let splash storage restore timers complete
  });
}
