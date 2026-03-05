import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

/// SQLiteHelper — única fuente de verdad para toda la persistencia local.
///
/// Tablas:
///   products       — catálogo de productos Nike
///   cart_items     — carrito de compras (persiste entre sesiones)
///   saved_cards    — tarjetas de crédito guardadas
///   user_prefs     — preferencias del usuario (método de pago, etc.)
///   orders         — historial de órdenes
///   order_items    — ítems de cada orden
class SQLiteHelper {
  static final SQLiteHelper instance = SQLiteHelper._();
  static Database? _db;

  SQLiteHelper._();

  Future<Database> get database async => _db ??= await _initDB();

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'nike_store.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // ─── Schema ──────────────────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int _) async {
    await db.execute('''
      CREATE TABLE products (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        category    TEXT    NOT NULL,
        price       REAL    NOT NULL,
        description TEXT    NOT NULL,
        stock       INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        productId   INTEGER NOT NULL UNIQUE,
        productName TEXT    NOT NULL,
        price       REAL    NOT NULL,
        quantity    INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_cards (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        cardHolder   TEXT    NOT NULL,
        maskedNumber TEXT    NOT NULL,
        expiry       TEXT    NOT NULL,
        cardType     TEXT    NOT NULL DEFAULT 'Mastercard',
        isDefault    INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE user_prefs (
        id                    INTEGER PRIMARY KEY CHECK (id = 1),
        preferredPayment      TEXT    NOT NULL DEFAULT 'Credit',
        saveCardData          INTEGER NOT NULL DEFAULT 1,
        lastPromoCode         TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        orderCode     TEXT    NOT NULL UNIQUE,
        totalAmount   REAL    NOT NULL,
        paymentMethod TEXT    NOT NULL,
        status        TEXT    NOT NULL DEFAULT 'completed',
        promoCode     TEXT,
        discount      REAL    NOT NULL DEFAULT 0.0,
        createdAt     TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId     INTEGER NOT NULL REFERENCES orders(id),
        productId   INTEGER NOT NULL REFERENCES products(id),
        productName TEXT    NOT NULL,
        unitPrice   REAL    NOT NULL,
        quantity    INTEGER NOT NULL
      )
    ''');

    // Índices útiles
    await db.execute('CREATE INDEX idx_cart_product    ON cart_items(productId)');
    await db.execute('CREATE INDEX idx_items_order     ON order_items(orderId)');
    await db.execute('CREATE INDEX idx_orders_created  ON orders(createdAt DESC)');

    // Datos iniciales
    await _seedProducts(db);
    await _seedPrefs(db);
  }

  // ─── Seed ─────────────────────────────────────────────────────────────────

  Future<void> _seedProducts(Database db) async {
    const products = [
      {'name': 'Nike Air Max 270',        'category': 'Running',    'price': 180.0, 'description': 'Unidad Air más grande hasta la fecha. Amortiguación máxima para el día a día.',   'stock': 25},
      {'name': 'Nike React Infinity Run', 'category': 'Running',    'price': 160.0, 'description': 'Diseñado para correr más y lesionarse menos. Espuma React ultrasuave.',           'stock': 18},
      {'name': 'Nike Zoom Pegasus 40',    'category': 'Running',    'price': 130.0, 'description': 'Versatilidad y amortiguación Zoom para cualquier corredor.',                      'stock': 22},
      {'name': 'Nike Air Force 1',        'category': 'Lifestyle',  'price': 110.0, 'description': 'El icónico diseño que revolucionó el baloncesto en 1982.',                        'stock': 40},
      {'name': 'Nike Dunk Low',           'category': 'Lifestyle',  'price': 110.0, 'description': 'Estilo retro del baloncesto universitario de los 80s.',                           'stock': 30},
      {'name': 'Nike Jordan 1 Retro High','category': 'Basketball', 'price': 180.0, 'description': 'El tenis más icónico de la historia del baloncesto.',                             'stock': 12},
      {'name': 'Nike Tech Fleece Jogger', 'category': 'Apparel',    'price': 110.0, 'description': 'Calor ligero con estilo urbano. Tejido Tech Fleece exclusivo.',                   'stock': 15},
      {'name': 'Nike Club Hoodie',        'category': 'Apparel',    'price':  65.0, 'description': 'Sudadera clásica con capucha para el día a día.',                                 'stock': 50},
    ];
    for (final p in products) await db.insert('products', p);
  }

  Future<void> _seedPrefs(Database db) async {
    await db.insert('user_prefs', {'id': 1, 'preferredPayment': 'Credit', 'saveCardData': 1});
  }

  // ─── PRODUCTS ─────────────────────────────────────────────────────────────

  Future<List<Product>> getProducts({String? category}) async {
    final db = await database;
    final rows = category == null
        ? await db.query('products', orderBy: 'category, name')
        : await db.query('products', where: 'category=?', whereArgs: [category], orderBy: 'name');
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final rows = await db.query('products', where: 'id=?', whereArgs: [id]);
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  Future<void> decreaseStock(Database db, int productId, int qty) async {
    await db.rawUpdate(
      'UPDATE products SET stock = stock - ? WHERE id = ? AND stock >= ?',
      [qty, productId, qty],
    );
  }

  // ─── CART ─────────────────────────────────────────────────────────────────

  Future<List<CartItem>> getCart() async {
    final db = await database;
    return (await db.query('cart_items')).map(CartItem.fromMap).toList();
  }

  Future<double> getCartTotal() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COALESCE(SUM(price * quantity), 0) AS t FROM cart_items');
    return (r.first['t'] as num).toDouble();
  }

  Future<int> getCartCount() async {
    final db = await database;
    final r = await db.rawQuery('SELECT COALESCE(SUM(quantity), 0) AS c FROM cart_items');
    return (r.first['c'] as num).toInt();
  }

  Future<void> addToCart(CartItem item) async {
    final db = await database;
    // INSERT OR IGNORE + UPDATE patrón upsert
    final existing = await db.query('cart_items',
        where: 'productId=?', whereArgs: [item.productId]);
    if (existing.isEmpty) {
      await db.insert('cart_items', item.toMap()..remove('id'));
    } else {
      await db.rawUpdate(
        'UPDATE cart_items SET quantity = quantity + ? WHERE productId = ?',
        [item.quantity, item.productId],
      );
    }
  }

  Future<void> updateCartQty(int productId, int qty) async {
    final db = await database;
    if (qty <= 0) {
      await db.delete('cart_items', where: 'productId=?', whereArgs: [productId]);
    } else {
      await db.update('cart_items', {'quantity': qty},
          where: 'productId=?', whereArgs: [productId]);
    }
  }

  Future<void> removeFromCart(int productId) async {
    final db = await database;
    await db.delete('cart_items', where: 'productId=?', whereArgs: [productId]);
  }

  Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart_items');
  }

  // ─── SAVED CARDS ──────────────────────────────────────────────────────────

  Future<List<SavedCard>> getSavedCards() async {
    final db = await database;
    return (await db.query('saved_cards', orderBy: 'isDefault DESC')).map(SavedCard.fromMap).toList();
  }

  Future<SavedCard?> getDefaultCard() async {
    final db = await database;
    final rows = await db.query('saved_cards', where: 'isDefault=1', limit: 1);
    if (rows.isEmpty) {
      final all = await db.query('saved_cards', limit: 1);
      return all.isEmpty ? null : SavedCard.fromMap(all.first);
    }
    return SavedCard.fromMap(rows.first);
  }

  Future<void> saveCard(SavedCard card) async {
    final db = await database;
    if (card.isDefault) {
      await db.update('saved_cards', {'isDefault': 0});
    }
    await db.insert('saved_cards', card.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCard(int cardId) async {
    final db = await database;
    await db.delete('saved_cards', where: 'id=?', whereArgs: [cardId]);
  }

  // ─── USER PREFS ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPrefs() async {
    final db = await database;
    final rows = await db.query('user_prefs', where: 'id=1');
    return rows.isEmpty
        ? {'preferredPayment': 'Credit', 'saveCardData': 1, 'lastPromoCode': null}
        : rows.first;
  }

  Future<void> updatePrefs(Map<String, dynamic> data) async {
    final db = await database;
    await db.update('user_prefs', data, where: 'id=1');
  }

  // ─── PROMO CODES ──────────────────────────────────────────────────────────

  static const Map<String, double> _promoCodes = {
    'PROMO20-08': 50.0,
    'NIKE2024':   30.0,
    'FIRST50':    50.0,
    'SALE15':     15.0,
  };

  double? validatePromo(String code) => _promoCodes[code.toUpperCase().trim()];

  // ─── ORDERS ───────────────────────────────────────────────────────────────

  Future<int> createOrder(Order order) async {
    final db = await database;
    return db.transaction((txn) async {
      final orderId = await txn.insert('orders', order.toMap()..remove('id'));
      for (final item in order.items) {
        await txn.insert('order_items', {
          'orderId':     orderId,
          'productId':   item.productId,
          'productName': item.productName,
          'unitPrice':   item.unitPrice,
          'quantity':    item.quantity,
        });
        await txn.rawUpdate(
          'UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
      return orderId;
    });
  }

  Future<List<Order>> getOrders() async {
    final db = await database;
    final rows = await db.query('orders', orderBy: 'createdAt DESC');
    final orders = rows.map(Order.fromMap).toList();
    for (final o in orders) {
      final itemRows = await db.query('order_items',
          where: 'orderId=?', whereArgs: [o.id]);
      o.items = itemRows.map(OrderItem.fromMap).toList();
    }
    return orders;
  }

  Future<Map<String, dynamic>> getSalesStats() async {
    final db = await database;
    final r = await db.rawQuery('''
      SELECT
        COUNT(*)                           AS totalOrders,
        COALESCE(SUM(totalAmount-discount), 0) AS totalRevenue,
        COALESCE(AVG(totalAmount-discount), 0) AS avgOrder
      FROM orders WHERE status = 'completed'
    ''');
    return r.first;
  }
}