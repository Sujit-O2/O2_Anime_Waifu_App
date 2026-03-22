import 'package:flutter_test/flutter_test.dart';

import 'package:o2_waifu/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const O2WaifuApp());
    await tester.pump();

    // App should show loading screen initially
    expect(find.text('Loading Zero Two...'), findsOneWidget);
  });
}
