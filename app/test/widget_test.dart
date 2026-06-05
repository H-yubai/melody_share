import 'package:flutter_test/flutter_test.dart';
import 'package:guangling/app.dart';
import 'package:guangling/services/music_handler.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    final handler = MusicHandler();
    await tester.pumpWidget(MelodyShareApp(handler: handler));
    expect(find.text('广陵'), findsNothing);
    handler.dispose();
  });
}
