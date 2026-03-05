import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/sqlite_helper.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import 'payment_confirm_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  const PaymentScreen({super.key, required this.total});
  @override State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String  _method   = 'Credit';
  bool    _saveCard = true;
  bool    _loading  = false;

  final _cardCtrl   = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl    = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _formKey    = GlobalKey<FormState>();

  static const _methods = ['PayPal', 'Credit', 'Wallet'];

  @override
  void initState() {
    super.initState();
    _loadPrefsAndCard();
  }

  Future<void> _loadPrefsAndCard() async {
    final prefs = await SQLiteHelper.instance.getPrefs();
    final card  = await SQLiteHelper.instance.getDefaultCard();
    if (mounted) setState(() {
      _method   = prefs['preferredPayment'] as String? ?? 'Credit';
      _saveCard = (prefs['saveCardData'] as int? ?? 1) == 1;
      if (card != null) {
        _holderCtrl.text = card.cardHolder;
        _cardCtrl.text   = '**** **** **** ${card.maskedNumber}';
        _expiryCtrl.text = card.expiry;
      }
    });
  }

  Future<void> _confirm() async {
    if (_method == 'Credit' && !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (_saveCard && _method == 'Credit' && _holderCtrl.text.isNotEmpty) {
      final digits = _cardCtrl.text.replaceAll(RegExp(r'\D'), '');
      final last4  = digits.length >= 4 ? digits.substring(digits.length - 4) : '0000';
      await SQLiteHelper.instance.saveCard(SavedCard(
        cardHolder: _holderCtrl.text, maskedNumber: last4,
        expiry: _expiryCtrl.text, cardType: 'Mastercard', isDefault: true,
      ));
    }

    await SQLiteHelper.instance.updatePrefs({
      'preferredPayment': _method,
      'saveCardData': _saveCard ? 1 : 0,
    });

    final cart  = await SQLiteHelper.instance.getCart();
    final order = Order(
      orderCode:     'NK-${DateTime.now().millisecondsSinceEpoch}',
      totalAmount:   widget.total,
      paymentMethod: _method,
      status:        'completed',
      createdAt:     DateTime.now(),
      items: cart.map((c) => OrderItem(
        orderId: 0, productId: c.productId, productName: c.productName,
        unitPrice: c.price, quantity: c.quantity,
      )).toList(),
    );

    final orderId = await SQLiteHelper.instance.createOrder(order);
    await SQLiteHelper.instance.clearCart();

    setState(() => _loading = false);
    if (!mounted) return;

    final card = await SQLiteHelper.instance.getDefaultCard();
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => PaymentConfirmScreen(
        order: order.copyWithId(orderId), defaultCard: card,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Payment data',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textDark)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Total price ────────────────────────────────────────────────
            Text('Total price', style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            const SizedBox(height: 4),
            Text('\$${widget.total.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                    fontSize: 36, fontWeight: FontWeight.w700, color: AppTheme.primary)),

            const SizedBox(height: 28),

            // ── Payment Method ─────────────────────────────────────────────
            Text('Payment Method', style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            Row(children: _methods.map((m) {
              final sel = m == _method;
              return Expanded(child: GestureDetector(
                onTap: () {
                  setState(() => _method = m);
                  SQLiteHelper.instance.updatePrefs({'preferredPayment': m});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: m != _methods.last ? 10 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: sel ? [BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 4))] : [],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(m, style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13,
                        color: sel ? Colors.white : AppTheme.primary)),
                    const SizedBox(width: 6),
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: sel ? Colors.white : AppTheme.primary, width: 1.5),
                        color: sel ? Colors.white.withOpacity(0.2) : Colors.transparent,
                      ),
                      child: Icon(Icons.check, size: 13,
                          color: sel ? Colors.white : AppTheme.primary),
                    ),
                  ]),
                ),
              ));
            }).toList()),

            if (_method == 'Credit') ...[
              const SizedBox(height: 28),

              // ── Card number ────────────────────────────────────────────
              Text('Card number', style: _labelStyle),
              const SizedBox(height: 10),
              _InputField(
                controller: _cardCtrl,
                hint: '★★★★  ★★★★  ★★★★  ★★★★',
                prefix: const _MCIcon(),
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly, _CardFmt()],
                validator: (v) => (v?.length ?? 0) < 19 ? 'Número de tarjeta inválido' : null,
              ),

              const SizedBox(height: 20),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Valid until
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Valid until', style: _labelStyle),
                  const SizedBox(height: 10),
                  _InputField(
                    controller: _expiryCtrl,
                    hint: 'Month / Year',
                    keyboardType: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly, _ExpiryFmt()],
                    validator: (v) => (v?.length ?? 0) < 5 ? 'Fecha inválida' : null,
                  ),
                ])),
                const SizedBox(width: 16),
                // CVV
                SizedBox(width: 110, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('CVV', style: _labelStyle),
                  const SizedBox(height: 10),
                  _InputField(
                    controller: _cvvCtrl,
                    hint: '★★★',
                    obscure: true,
                    keyboardType: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                    validator: (v) => (v?.length ?? 0) < 3 ? 'CVV inválido' : null,
                  ),
                ])),
              ]),

              const SizedBox(height: 20),
              Text('Card holder', style: _labelStyle),
              const SizedBox(height: 10),
              _InputField(
                controller: _holderCtrl,
                hint: 'Your name and surname',
                cap: TextCapitalization.words,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Ingresa el nombre' : null,
              ),

              const SizedBox(height: 20),
              // ── Save card toggle ───────────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Save card data for future payments',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textDark)),
                Switch(
                  value: _saveCard,
                  activeColor: Colors.white,
                  activeTrackColor: AppTheme.primary,
                  onChanged: (v) {
                    setState(() => _saveCard = v);
                    SQLiteHelper.instance.updatePrefs({'saveCardData': v ? 1 : 0});
                  },
                ),
              ]),
            ],

            const SizedBox(height: 36),

            // ── Proceed to confirm button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: _loading
                    ? const SizedBox(height: 22, width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Proceed to confirm',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  TextStyle get _labelStyle => GoogleFonts.poppins(
      fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark);
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _MCIcon extends StatelessWidget {
  const _MCIcon();
  @override
  Widget build(BuildContext context) => SizedBox(width: 38, height: 24,
    child: Stack(children: [
      Positioned(left: 0, child: Container(width: 24, height: 24,
          decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle))),
      Positioned(left: 12, child: Container(width: 24, height: 24,
          decoration: BoxDecoration(
              color: const Color(0xFFF79E1B).withOpacity(0.9), shape: BoxShape.circle))),
    ]),
  );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? prefix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;
  final TextCapitalization cap;

  const _InputField({
    required this.controller, required this.hint,
    this.obscure = false, this.prefix, this.keyboardType,
    this.formatters, this.validator, this.cap = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: formatters,
    validator: validator,
    obscureText: obscure,
    textCapitalization: cap,
    style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textDark),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefix != null
          ? Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: prefix)
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.4), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
  );
}

class _CardFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final t = nv.text.replaceAll(' ', '');
    if (t.length > 16) return old;
    final buf = StringBuffer();
    for (int i = 0; i < t.length; i++) {
      buf.write(t[i]);
      if ((i + 1) % 4 == 0 && i + 1 != t.length) buf.write(' ');
    }
    return TextEditingValue(text: buf.toString(),
        selection: TextSelection.collapsed(offset: buf.length));
  }
}

class _ExpiryFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final t = nv.text.replaceAll('/', '');
    if (t.length > 4) return old;
    if (t.length >= 2) {
      final f = '${t.substring(0, 2)}/${t.substring(2)}';
      return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
    }
    return nv;
  }
}