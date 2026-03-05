import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/products_screen.dart';
import 'screens/order_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const NikeStoreApp());
}

class NikeStoreApp extends StatelessWidget {
  const NikeStoreApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Nike Store',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    home: const _HomeNav(),
  );
}

class _HomeNav extends StatefulWidget {
  const _HomeNav();
  @override State<_HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<_HomeNav> {
  int _idx = 0;
  static const _screens = [ProductsScreen(), OrderHistoryScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _idx, children: _screens),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _idx,
      onDestinationSelected: (i) => setState(() => _idx = i),
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.primaryLight,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront, color: AppTheme.primary),
          label: 'Tienda',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primary),
          label: 'Pedidos',
        ),
      ],
    ),
  );
}