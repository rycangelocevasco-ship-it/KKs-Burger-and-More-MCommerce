class ProductVariant {
  final String label;
  final double price;

  const ProductVariant({
    required this.label,
    required this.price,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    final value = map['price'];

    return ProductVariant(
      label: (map['label'] ?? '').toString(),
      price: value is num
          ? value.toDouble()
          : double.tryParse('$value') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'price': price,
      };
}

class Product {
  final String id;
  final String name;
  final String category;
  final String subCategory;
  final String ingredients;
  final double price;
  final String imageUrl;
  final int stock;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    this.subCategory = '',
    this.ingredients = '',
    required this.price,
    required this.imageUrl,
    this.stock = 0,
    this.variants = const [],
  });

  String get description => ingredients;

  bool get hasVariants => variants.isNotEmpty;

  static const List<String> categories = [
    'Burgers',
    'Pick A - Pick A',
    'Hot Dawgz',
    'Pasta',
    'Chicken Wings',
    'Rice Meals',
    'Drinks',
  ];

  static const List<String> drinkTypes = [
    'Milk Tea',
    'Ice Blended',
    'Iced Coffee',
    'Fruitea',
    'Yakult Series',
    'Italian Soda',
  ];

  static const List<String> drinkFlavors = [
    'Strawberry',
    'Green Apple',
    'Four Seasons',
    'Mixed Berries',
    'Lychee',
    'Blueberry',
    'Mango',
    'Passion Fruit',
    'Peach',
    'Lemon',
  ];

  static const List<String> riceMealAddOns = [
    'Extra Rice',
    'Egg',
  ];

  static const double extraRicePrice = 20;
  static const double extraEggPrice = 15;

  static List<Product> get menu {
    final result = <Product>[
      // =====================================================
      // BURGERS
      // =====================================================

      const Product(
        id: 'burger_classic',
        name: 'CLASSIC BURGER',
        category: 'Burgers',
        price: 109,
        imageUrl: '',
      ),
      const Product(
        id: 'burger_cheesy',
        name: 'CHEESY BURGER',
        category: 'Burgers',
        price: 129,
        imageUrl: '',
      ),
      const Product(
        id: 'burger_with_egg',
        name: 'BURGER W/ EGG',
        category: 'Burgers',
        price: 129,
        imageUrl: '',
      ),
      const Product(
        id: 'burger_ham_egg',
        name: 'HAM & EGG',
        category: 'Burgers',
        price: 125,
        imageUrl: '',
      ),
      const Product(
        id: 'burger_bounty',
        name: 'BOUNTY BURGER',
        category: 'Burgers',
        price: 159,
        imageUrl: '',
      ),
      const Product(
        id: 'burger_double_cheesy',
        name: 'DOUBLE CHEESY',
        category: 'Burgers',
        price: 159,
        imageUrl: '',
      ),
      const Product(
        id: 'burger_rasher',
        name: 'RASHER BURGER',
        category: 'Burgers',
        price: 169,
        imageUrl: '',
      ),
      const Product(
        id: 'burger_aloha',
        name: 'ALOHA BURGER',
        category: 'Burgers',
        price: 169,
        imageUrl: '',
      ),
      const Product(
        id: 'burger_knyx_bomb',
        name: 'KNYX BOMB',
        category: 'Burgers',
        price: 209,
        imageUrl: '',
      ),
      const Product(
        id: 'burger_kzy',
        name: 'KZY BURGER',
        category: 'Burgers',
        price: 209,
        imageUrl: '',
      ),

      // =====================================================
      // PICK A - PICK A
      // =====================================================

     
    
      const Product(
        id: 'snack_cheesy_fries',
        name: 'CHEESY FRIES',
        category: 'Pick A - Pick A',
        price: 69,
        imageUrl: '',
      ),
      const Product(
        id: 'snack_cheesy_nachos',
        name: 'CHEESY NACHOS',
        category: 'Pick A - Pick A',
        price: 69,
        imageUrl: '',
      ),
      const Product(
        id: 'snack_jojo_mojos',
        name: 'JOJO MOJOS',
        category: 'Pick A - Pick A',
        price: 79,
        imageUrl: '',
      ),
      const Product(
        id: 'snack_bucket_fries',
        name: 'BUCKET FRIES',
        category: 'Pick A - Pick A',
        price: 85,
        imageUrl: '',
      ),
      const Product(
        id: 'snack_b1g1_fries',
        name: 'BUY 1 GET 1 FRIES',
        category: 'Pick A - Pick A',
        price: 50,
        imageUrl: '',
      ),
      const Product(
        id: 'snack_onion_rings',
        name: 'ONION RINGS',
        category: 'Pick A - Pick A',
        price: 69,
        imageUrl: '',
      ),

      // =====================================================
      // HOT DAWGZ
      // =====================================================

      const Product(
        id: 'hotdog_cheesy_footlong',
        name: 'CHEESY FOOTLONG',
        category: 'Hot Dawgz',
        price: 69,
        imageUrl: '',
      ),
      const Product(
        id: 'hotdog_cheesiest_footlong',
        name: 'CHEESIEST FOOTLONG',
        category: 'Hot Dawgz',
        price: 79,
        imageUrl: '',
      ),
      const Product(
        id: 'hotdog_classic_footlong',
        name: 'CLASSIC FOOTLONG',
        category: 'Hot Dawgz',
        price: 55,
        imageUrl: '',
      ),
      const Product(
        id: 'hotdog_cheesy_hungarian',
        name: 'CHEESY HUNGARIAN',
        category: 'Hot Dawgz',
        price: 85,
        imageUrl: '',
      ),

      // =====================================================
      // PASTA
      // =====================================================

      const Product(
        id: 'pasta_mac_chiz',
        name: 'MAC & CHIZ',
        category: 'Pasta',
        price: 80,
        imageUrl: '',
      ),

      // =====================================================
      // RICE MEALS
      // =====================================================

      const Product(
        id: 'rice_chicken',
        name: 'Chicken Rice Meal',
        category: 'Rice Meals',
        price: 119,
        imageUrl: '',
      ),
    
      
    ];

    // =======================================================
    // CHICKEN WINGS
    // =======================================================

    const wingPrices = <String, double>{
      '6 PIECES': 189,
      '12 PIECES': 359,
      '16 PIECES': 539,
      '2 PCS. WITH RICE': 99,
    };

    const wingFlavors = [
      'Buffalo',
      'Honey Garlic',
      'Korean BBQ',
      'Cheesy Bacon',
    ];

    for (final flavor in wingFlavors) {
      final flavorId = flavor
          .toLowerCase()
          .replaceAll(' ', '_');

      result.add(
        Product(
          id: 'wings_$flavorId',
          name: '$flavor Wings',
          category: 'Chicken Wings',
          price: 189,
          imageUrl: '',
          variants: wingPrices.entries
              .map(
                (entry) => ProductVariant(
                  label: entry.key,
                  price: entry.value,
                ),
              )
              .toList(),
        ),
      );
    }

    return result;
  }
}