import 'package:flutter_test/flutter_test.dart';
import 'package:jugnu/testing.dart';
import 'package:jugnu_example/main.dart';

void main() {
  testWidgets('the account tab needs a sign-in', (tester) async {
    await pumpRouter(tester, router);
    await expectRedirect(
      tester,
      router,
      from: '/account',
      to: '/login?from=/account',
    );
  });

  testWidgets('product links open the product page', (tester) async {
    await pumpRouter(tester, router);
    await expectDeepLink(
      tester,
      router,
      'https://shop.example.com/shop/product/3?color=blue',
      opens: '/shop/product/3?color=blue',
    );
    expect(find.text('Color: blue'), findsOneWidget);
  });
}
