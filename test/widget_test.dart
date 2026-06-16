import 'package:flutter_test/flutter_test.dart';

import 'package:nail_lab_ai/main.dart';
import 'package:nail_lab_ai/widgets/logo_placeholder.dart';

void main() {
  testWidgets('shows logo placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const NailLabApp());

    expect(find.byType(LogoPlaceholder), findsOneWidget);
  });
}
