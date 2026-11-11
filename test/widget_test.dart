import 'package:flutter_test/flutter_test.dart';
import 'package:networking/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NetworkHunterApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NetworkHunterApp), findsOneWidget);
  });
}
