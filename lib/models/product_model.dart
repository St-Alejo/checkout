class Product {
  final int?   id;
  final String name;
  final String category;
  final double price;
  final String description;
  final int    stock;

  const Product({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.stock,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'category': category,
    'price': price, 'description': description, 'stock': stock,
  };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'], name: m['name'], category: m['category'],
    price: m['price'], description: m['description'], stock: m['stock'],
  );
}