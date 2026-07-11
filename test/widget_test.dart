import 'package:flutter_test/flutter_test.dart';
import 'package:indicab/layout/app.dart';
import 'package:indicab/core/constants/Strings.dart';

void main() {
  testWidgets('app boots to the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const IndicabApp());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.title_tag), findsOneWidget);
  });
}
