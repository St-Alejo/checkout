import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/sqlite_helper.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _items = [];
  double _total = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final items = await SQLiteHelper.instance.getCart();
    final total = await SQLiteHelper.instance.getCartTotal();
    if (mounted) setState(() { _items = items; _total = total; _loading = false; });
  }

  Future<void> _updateQty(int productId, int qty) async {
    await SQLiteHelper.instance.updateCartQty(productId, qty);
    _load();
  }

  Future<void> _remove(int productId) async {
    await SQLiteHelper.instance.removeFromCart(productId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () async { await SQLiteHelper.instance.clearCart(); _load(); },
              child: Text('Limpiar', style: GoogleFonts.poppins(color: Colors.red, fontSize: 13)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _items.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.textGrey.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text('Tu carrito está vacío',
            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 16)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Explorar productos',
              style: GoogleFonts.poppins(color: AppTheme.primary)),
        ),
      ]))
          : Column(children: [
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (_, i) => _CartTile(
            item: _items[i],
            onAdd:    () => _updateQty(_items[i].productId, _items[i].quantity + 1),
            onMinus:  () => _updateQty(_items[i].productId, _items[i].quantity - 1),
            onDelete: () => _remove(_items[i].productId),
          ),
        )),
        _Summary(
          total: _total,
          count: _items.length,
          onCheckout: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PaymentScreen(total: _total)),
          ).then((_) => _load()),
        ),
      ]),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onAdd, onMinus, onDelete;
  const _CartTile({required this.item, required this.onAdd, required this.onMinus, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.directions_run_outlined, color: AppTheme.primary, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.productName,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
          Text('\$${item.price.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
        ])),
        Row(children: [
          _QBtn(icon: Icons.remove, onTap: onMinus),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('${item.quantity}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16))),
          _QBtn(icon: Icons.add, onTap: onAdd),
        ]),
        const SizedBox(width: 8),
        GestureDetector(onTap: onDelete,
            child: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
      ]),
    );
  }
}

class _QBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _QBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 14, color: AppTheme.textDark),
    ),
  );
}

class _Summary extends StatelessWidget {
  final double total; final int count; final VoidCallback onCheckout;
  const _Summary({required this.total, required this.count, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0,-4))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$count artículo(s)', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          Text('\$${total.toStringAsFixed(2)}', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
        ]),
        const Divider(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
          Text('\$${total.toStringAsFixed(2)}', style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.primary)),
        ]),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onCheckout, child: const Text('Proceder al pago')),
      ]),
    );
  }
}