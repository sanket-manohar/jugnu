import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugnu/jugnu.dart';

/// Pretend sign-in state. A real app would use its auth service.
final signedIn = ValueNotifier(false);

enum Sort { popular, newest }

final productId = RouteParam.integer('id');
final color = RouteParam.string('color', defaultValue: 'black');
final sort = RouteParam.enumeration(
  'sort',
  Sort.values,
  defaultValue: Sort.popular,
);

final router = GoRouter(
  initialLocation: '/shop',
  refreshListenable: signedIn,
  redirect: guards([
    (context, state) {
      debugPrint('navigating to ${state.uri}');
      return null;
    },
    (context, state) {
      final private = state.uri.path.startsWith('/account');
      return private && !signedIn.value
          ? '/login?from=${state.uri.path}'
          : null;
    },
  ]),
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shop',
              name: 'shop',
              builder: (context, state) => ShopPage(sort: sort.read(state)),
              routes: [
                GoRoute(
                  path: 'product/:id',
                  name: 'product',
                  builder: (context, state) => ProductPage(
                    id: productId.read(state),
                    color: color.read(state),
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/account',
              name: 'account',
              builder: (context, state) => const AccountPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/colors',
      name: 'colors',
      builder: (context, state) => const ColorPickerPage(),
    ),
  ],
);

void main() {
  JugnuDebug.attach(router);
  runApp(
    MaterialApp.router(
      title: 'jugnu example',
      theme: ThemeData(colorSchemeSeed: const Color(0xFFB7791F)),
      routerConfig: router,
    ),
  );
}

class HomeShell extends StatelessWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.switchTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

class ShopPage extends StatelessWidget {
  const ShopPage({required this.sort, super.key});

  final Sort sort;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shop · ${sort.name}')),
      body: ListView(
        children: [
          for (var id = 1; id <= 5; id++)
            ListTile(
              title: Text('Product $id'),
              onTap: () => context.goNamed(
                'product',
                pathParameters: {productId.name: productId.encode(id)},
              ),
            ),
        ],
      ),
    );
  }
}

class ProductPage extends StatelessWidget {
  const ProductPage({required this.id, required this.color, super.key});

  final int id;
  final String color;

  @override
  Widget build(BuildContext context) {
    final link = router
        .deepLinks(scheme: 'https', host: 'shop.example.com')
        .build(
          'product',
          pathParameters: {'id': id},
          queryParameters: {'color': color},
        );

    return Scaffold(
      appBar: AppBar(title: Text('Product $id')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Color: $color'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final picked = await context.pushForResult<String>('/colors');
                if (picked != null && context.mounted) {
                  context.goNamed(
                    'product',
                    pathParameters: {'id': '$id'},
                    queryParameters: {'color': picked},
                  );
                }
              },
              child: const Text('Pick a color'),
            ),
            const SizedBox(height: 24),
            const Text('Share link'),
            const SizedBox(height: 4),
            SelectableText(
              '$link',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class ColorPickerPage extends StatelessWidget {
  const ColorPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick a color')),
      body: ListView(
        children: [
          for (final name in ['black', 'blue', 'red'])
            ListTile(
              title: Text(name),
              onTap: () => context.popWithResult(name, fallback: '/shop'),
            ),
        ],
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: TextButton(
          onPressed: () => signedIn.value = false,
          child: const Text('Sign out'),
        ),
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            signedIn.value = true;
            context.go(from ?? '/shop');
          },
          child: const Text('Sign in'),
        ),
      ),
    );
  }
}
