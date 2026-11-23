import 'package:flutter_test/flutter_test.dart';
import 'package:govipala/main.dart';
import 'package:govipala/widgets/govi_button.dart';

void main() {
  testWidgets('Govipala phone entry screen renders initial UI', (WidgetTester tester) async {
    await tester.pumpWidget(const GovipalaApp());

    // Verify app title and phone entry instruction texts are displayed
    expect(find.text('ගොවිපල (Govipala)'), findsOneWidget);
    expect(find.text('ඔබගේ දුරකථන අංකය ඇතුළත් කරන්න'), findsOneWidget);
    expect(find.text('🇱🇰 +94'), findsOneWidget);

    // Verify main action button is present
    expect(find.byType(GoviButton), findsOneWidget);
  });
}
