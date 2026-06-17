import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nail_lab_ai/main.dart';
import 'package:nail_lab_ai/services/language_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('onboarding has no title text', (WidgetTester tester) async {
    await LanguageService.instance.ensureLoaded();
    await tester.pumpWidget(const NailLabApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('See Your Mani Live!'), findsNothing);
    expect(find.text('Design & Create Your Own Nail Art'), findsNothing);
  });
}
