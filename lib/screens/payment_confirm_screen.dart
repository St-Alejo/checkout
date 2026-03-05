import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import 'products_screen.dart';

class PaymentConfirmScreen extends StatefulWidget {
  final Order order;
  final SavedCard? defaultCard;
  const PaymentConfirmScreen({super.key, required this.order, this.defaultCard});
  @override State<PaymentConfirmScreen> createState() => _PaymentConfirmScreenState();
}

class _PaymentConfirmScreenState extends State<PaymentConfirmScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<Offset> _slide =
  Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  late final Animation<double> _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

  @override
  void initState() { super.initState(); Future.microtask(_ctrl.forward); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _goHome() => Navigator.pushAndRemoveUntil(
      context, MaterialPageRoute(builder: (_) => const ProductsScreen()), (_) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        automaticallyImplyLeading: false,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goHome),
        title: Text('Payment', style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textDark)),
        elevation: 0,
      ),
      body: FadeTransition(opacity: _fade, child: SlideTransition(position: _slide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Promo Banner Nike ──────────────────────────────────────────
            _NikeBanner(),
            const SizedBox(height: 28),

            // ── Payment information ────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Payment information', style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text('Edit', style: GoogleFonts.poppins(
                    color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ]),
            const SizedBox(height: 12),
            _PaymentInfoCard(card: widget.defaultCard, method: widget.order.paymentMethod),

            const SizedBox(height: 24),

            // ── Use promo code ─────────────────────────────────────────────
            Text('Use promo code', style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14)),
              child: Text(
                widget.order.promoCode ?? 'Sin código',
                style: GoogleFonts.poppins(
                  color: widget.order.promoCode != null
                      ? AppTheme.primary
                      : AppTheme.textGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ── Pay button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _SuccessDialog(order: widget.order, onDone: _goHome),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: Text('Pay', style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      )),
    );
  }
}

// ─── Nike Promo Banner ────────────────────────────────────────────────────────

class _NikeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 168,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B8CFF), Color(0xFF5C6EFA), Color(0xFF4B5EFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(children: [
        // Círculo decorativo fondo
        Positioned(right: -30, top: -30, child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)))),
        // Número grande decorativo
        Positioned(right: 16, bottom: -18,
            child: Text('\$5',
                style: GoogleFonts.poppins(
                    fontSize: 120, fontWeight: FontWeight.w900,
                    color: Colors.white.withOpacity(0.10)))),
        // Contenido
        Padding(padding: const EdgeInsets.all(22), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nike swoosh (ícono aproximado)
            Container(
              width: 32, height: 20,
              child: CustomPaint(painter: _SwoshPainter()),
            ),
            const SizedBox(height: 10),
            Text('\$50 off',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            Text('On your first order',
                style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9), fontSize: 14)),
            const SizedBox(height: 8),
            Text('* Promo code valid for orders over \$150.',
                style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.65), fontSize: 11)),
          ],
        )),
      ]),
    );
  }
}

class _SwoshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.5, -size.height * 0.2,
          size.width, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.5,
          size.width * 0.15, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(_) => false;
}

// ─── Payment Info Card ────────────────────────────────────────────────────────

class _PaymentInfoCard extends StatelessWidget {
  final SavedCard? card;
  final String method;
  const _PaymentInfoCard({this.card, required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        // Mastercard icon
        SizedBox(width: 44, height: 28, child: Stack(children: [
          Positioned(left: 0, child: Container(width: 26, height: 26,
              decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle))),
          Positioned(left: 14, child: Container(width: 26, height: 26,
              decoration: BoxDecoration(
                  color: const Color(0xFFF79E1B).withOpacity(0.9), shape: BoxShape.circle))),
        ])),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            card?.cardHolder ?? 'Card holder',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark),
          ),
          Text(
            card != null
                ? 'Master Card ending **${card!.maskedNumber.length >= 2 ? card!.maskedNumber.substring(card!.maskedNumber.length - 2) : card!.maskedNumber}'
                : method,
            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
          ),
        ]),
      ]),
    );
  }
}

// ─── Success Dialog ───────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  final Order order;
  final VoidCallback onDone;
  const _SuccessDialog({required this.order, required this.onDone});

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(padding: const EdgeInsets.all(28), child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 80, height: 80,
            decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: AppTheme.success, size: 40)),
        const SizedBox(height: 16),
        Text('¡Pago Exitoso!', style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, fontSize: 22, color: AppTheme.textDark)),
        const SizedBox(height: 8),
        Text(order.orderCode, style: GoogleFonts.poppins(
            color: AppTheme.textGrey, fontSize: 12)),
        const SizedBox(height: 4),
        Text('\$${order.finalAmount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 28, color: AppTheme.primary)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: onDone, child: const Text('Seguir Comprando')),
      ],
    )),
  );
}