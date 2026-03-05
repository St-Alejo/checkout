import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../database/sqlite_helper.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> _orders = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final orders = await SQLiteHelper.instance.getOrders();
    final stats  = await SQLiteHelper.instance.getSalesStats();
    if (mounted) setState(() { _orders = orders; _stats = stats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Pedidos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(children: [
        if ((_stats['totalOrders'] as int? ?? 0) > 0)
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            _StatCard(label: 'Órdenes', value: '${_stats['totalOrders']}',
                icon: Icons.receipt_long_outlined, color: AppTheme.primary),
            const SizedBox(width: 12),
            _StatCard(
                label: 'Ingresos',
                value: '\$${(_stats['totalRevenue'] as num? ?? 0).toStringAsFixed(0)}',
                icon: Icons.attach_money, color: AppTheme.success),
          ])),
        Expanded(child: _orders.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.receipt_outlined, size: 80,
              color: AppTheme.textGrey.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No hay pedidos aún',
              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 16)),
        ]))
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _orders.length,
          itemBuilder: (_, i) => _OrderTile(order: _orders[i]),
        )),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
          Text(value, style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ]),
      ]),
    ),
  );
}

class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order});

  Color get _color => switch (order.status) {
    'completed' => AppTheme.success,
    'cancelled' => Colors.red,
    _ => Colors.orange,
  };
  String get _label => switch (order.status) {
    'completed' => 'Completado',
    'cancelled' => 'Cancelado',
    _ => 'Pendiente',
  };

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(order.orderCode, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Text(_label, style: GoogleFonts.poppins(
                color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(fmt.format(order.createdAt),
            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${order.items.length} artículo(s) · ${order.paymentMethod}',
              style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
          Text('\$${order.finalAmount.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.primary)),
        ]),
        if (order.promoCode != null) Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            const Icon(Icons.local_offer_outlined, size: 12, color: AppTheme.success),
            const SizedBox(width: 4),
            Text('${order.promoCode} (-\$${order.discount.toStringAsFixed(0)})',
                style: GoogleFonts.poppins(color: AppTheme.success, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}