import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brain_think/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BrainThinkApp()));
    await tester.pump();
    expect(find.byType(BrainThinkApp), findsOneWidget);
  });
}
