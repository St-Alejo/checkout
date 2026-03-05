import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/sqlite_helper.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import 'cart_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  String _cat = 'All';
  int    _cartCount = 0;
  bool   _loading = true;

  static const List<String> _cats = ['All','Running','Lifestyle','Basketball','Apparel'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final products = await SQLiteHelper.instance.getProducts();
    final count    = await SQLiteHelper.instance.getCartCount();
    if (mounted) setState(() { _products = products; _cartCount = count; _loading = false; });
  }

  List<Product> get _filtered =>
      _cat == 'All' ? _products : _products.where((p) => p.category == _cat).toList();

  Future<void> _addToCart(Product p) async {
    await SQLiteHelper.instance.addToCart(
      CartItem(productId: p.id!, productName: p.name, price: p.price, quantity: 1),
    );
    final count = await SQLiteHelper.instance.getCartCount();
    if (mounted) {
      setState(() => _cartCount = count);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${p.name} agregado al carrito'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(children: [
          Text('Nike Store', style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 20, color: AppTheme.primary)),
          Text('Caso de Estudio · SQLite', style: GoogleFonts.poppins(
              fontSize: 11, color: AppTheme.textGrey)),
        ]),
        actions: [
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ).then((_) => _load()),
            ),
            if (_cartCount > 0) Positioned(right: 8, top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  child: Text('$_cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                )),
          ]),
        ],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: 44, child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: _cats.length,
          itemBuilder: (_, i) {
            final sel = _cats[i] == _cat;
            return GestureDetector(
              onTap: () => setState(() => _cat = _cats[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: sel ? [BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0,3))] : [],
                ),
                child: Text(_cats[i], style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: sel ? Colors.white : AppTheme.textGrey)),
              ),
            );
          },
        )),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('${_filtered.length} productos',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
        ),
        const SizedBox(height: 8),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.72,
            crossAxisSpacing: 12, mainAxisSpacing: 12,
          ),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => _ProductCard(
            product: _filtered[i],
            onAdd: () => _addToCart(_filtered[i]),
          ),
        )),
      ]),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  const _ProductCard({required this.product, required this.onAdd});

  IconData get _icon => switch (product.category) {
    'Apparel'    => Icons.checkroom_outlined,
    'Basketball' => Icons.sports_basketball_outlined,
    _            => Icons.directions_run_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0,4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 130,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Center(child: Icon(_icon, size: 56, color: AppTheme.primary.withOpacity(0.45))),
        ),
        Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.category, style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textGrey)),
            Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('\$${product.price.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ]),
          ],
        )),
      ]),
    );
  }
}