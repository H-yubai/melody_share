import 'package:flutter_test/flutter_test.dart';
import 'package:melody_share/app.dart';
import 'package:melody_share/services/music_handler.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    final handler = MusicHandler();
    await tester.pumpWidget(MelodyShareApp(handler: handler));
    expect(find.text('MelodyShare'), findsNothing);
    handler.dispose();
  });
}
