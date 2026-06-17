import 'package:flutter_test/flutter_test.dart';

import 'package:nail_lab_ai/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding has no title text', (WidgetTester tester) async {
    await tester.pumpWidget(const NailLabApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('See Your Mani Live!'), findsNothing);
    expect(find.text('Design & Create Your Own Nail Art'), findsNothing);
  });
}
