
import 'dart:async';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../services/database_service.dart';
import 'profile/profile_page.dart';

part 'main_screen_home.dart';
part 'main_screen_cart.dart';
part 'main_screen_orders.dart';
part 'main_screen_widgets.dart';

const _brown = Color(0xFF332719);
const _yellow = Color(0xFFFFC928);

// FIXED DRINK SIZE PRICES
const Map<String, Map<String, double>> _drinkSizePrices = {
  'Milk Tea': {
    'Medium': 49,
    'Large': 59,
  },
  'Iced Coffee': {
    'Medium': 79,
    'Large': 89,
  },
  'Ice Blended': {
    'Medium': 89,
    'Large': 99,
  },
  'Fruitea': {
    'Medium': 39,
    'Large': 49,
  },
  'Yakult Series': {
    'Medium': 55,
    'Large': 65,
  },
  'Italian Soda': {
    'Medium': 55,
    'Large': 65,
  },
};

class _CartLine {
  final Product product;
  final String variant;
  final double price;
  int quantity = 1;

  _CartLine({
    required this.product,
    required this.variant,
    required this.price,
  });

  String get key => '${product.id}::$variant';

  String get displayName =>
      variant.isEmpty ? product.name : '${product.name} ($variant)';
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  String _category = 'All';
  String _drinkSubCategory = 'All Drinks';
  String _search = '';

  final Map<String, _CartLine> _cart = {};

  String _orderType = 'Pickup';
  String _paymentMethod = 'Cash';
  String? _deliveryLocation;

 bool _checkingOut = false;
bool _uploadingReceipt = false;

// Reuse the same ID if an order request needs to be retried.
String? _pendingOrderId;

  Uint8List? _gcashReceipt;
  String _gcashReceiptName = '';
  String _gcashReceiptContentType = 'image/jpeg';

  Future<Map<String, dynamic>>? _profileFuture;
  Map<String, dynamic> _homeProfileData = {};

  List<Product> _products = [];
  bool _loadingProducts = true;
  String? _productError;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _productSubscription;

  final Map<String, double> _deliveryRates = {
    'Angono, Rizal': 20,
    'Taytay, Rizal': 40,
    'Binangonan, Rizal': 40,
    'Cainta, Rizal': 60,
    'Antipolo, Rizal': 70,
  };

  @override
  void initState() {
    super.initState();
    _loadHomeProfile();
    _listenProducts();
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    super.dispose();
  }

  void _refresh(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  void _loadHomeProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _profileFuture = DatabaseService().getUserProfile(user.uid);

    _profileFuture!.then((data) {
      if (mounted) {
        _refresh(() => _homeProfileData = data);
      }
    }).catchError((error) {
      debugPrint('PROFILE ERROR: $error');
    });
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  int _integer(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  // FIRESTORE PRODUCT LISTENER

  void _listenProducts() {
    _productSubscription = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen((snapshot) {
      final loaded = snapshot.docs.map((doc) {
        final data = doc.data();

        final savedCategory =
            (data['category'] ?? 'Others').toString().trim();

        final savedSubCategory =
            (data['subCategory'] ?? data['drinkType'] ?? '')
                .toString()
                .trim();

        final normalizedCategory = savedCategory.toLowerCase();

        final isLegacyDrinkType = Product.drinkTypes.any(
          (type) => type.toLowerCase() == normalizedCategory,
        );

        final isLegacyItalian =
            savedCategory == 'Italian Series' ||
            savedSubCategory == 'Italian Series';

        final isLegacyRice =
            doc.id == 'rice_1' ||
            doc.id == 'rice_2' ||
            doc.id == 'rice_3';

        String category;
        String subCategory = savedSubCategory;

        if (isLegacyDrinkType || isLegacyItalian) {
          category = 'Drinks';
          subCategory = isLegacyItalian
              ? 'Italian Soda'
              : savedCategory;
        } else if (normalizedCategory == 'drinks') {
          category = 'Drinks';
        } else if (savedCategory == 'Fries') {
          category = 'Pick A - Pick A';
        } else if (savedCategory == 'Rice Meals' || isLegacyRice) {
          category = 'Rice Meals';
        } else {
          category = savedCategory;
        }

        final variantsRaw = data['variants'];

        final variants = variantsRaw is List
            ? variantsRaw
                .whereType<Map>()
                .map(
                  (item) => ProductVariant.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where(
                  (variant) =>
                      variant.label.isNotEmpty &&
                      variant.price > 0,
                )
                .toList()
            : <ProductVariant>[];

        return Product(
          id: doc.id,
          name: (data['name'] ?? 'Unnamed Product').toString(),
          category: category,
          subCategory: subCategory,
          ingredients: category == 'Burgers'
              ? (data['ingredients'] ?? '').toString()
              : '',
          price: _number(data['price']),
          imageUrl: (data['imageUrl'] ?? '').toString(),
          stock: _integer(data['stock'])
              .clamp(0, 1 << 30)
              .toInt(),
          variants: variants,
        );
      }).toList();

      if (!mounted) return;

      _refresh(() {
        _products = loaded;
        _loadingProducts = false;
        _productError = null;
      });
    }, onError: (error) {
      debugPrint('PRODUCT STREAM ERROR: $error');

      if (!mounted) return;

      _refresh(() {
        _loadingProducts = false;
        _productError = error.toString();
      });
    });
  }

  // ALL PRODUCTS

  List<Product> get _allProducts {
    final combined = <String, Product>{
      for (final product in Product.menu) product.id: product,
    };

    for (final product in _products) {
      combined[product.id] = product;
    }

    return combined.values.toList();
  }

  // FILTERED PRODUCTS

  List<Product> get _filteredProducts {
    return _allProducts.where((product) {
      final categoryMatch = _category == 'All' ||
          product.category.toLowerCase() == _category.toLowerCase();

      final drinkSubCategoryMatch =
          _category != 'Drinks' ||
          _drinkSubCategory == 'All Drinks' ||
          product.subCategory.toLowerCase() ==
              _drinkSubCategory.toLowerCase();

      final searchMatch =
          product.name.toLowerCase().contains(_search.toLowerCase()) ||
          product.subCategory.toLowerCase().contains(
                _search.toLowerCase(),
              );

      return categoryMatch && drinkSubCategoryMatch && searchMatch;
    }).toList();
  }

  // CART TOTALS

  double get _total => _cart.values.fold(
        0,
        (runningTotal, line) =>
            runningTotal + line.price * line.quantity,
      );

  int get _cartCount => _cart.values.fold(
        0,
        (runningTotal, line) => runningTotal + line.quantity,
      );

  double get _currentDeliveryFee {
    if (_orderType == 'Pickup' || _deliveryLocation == null) {
      return 0;
    }

    return _deliveryRates[_deliveryLocation] ?? 0;
  }

  double get _grandTotal => _total + _currentDeliveryFee;

  void _showMessage(String message, {Color? color}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // DRINK SIZE OPTIONS

  List<ProductVariant> _getDrinkVariants(Product product) {
    final prices = _drinkSizePrices[product.subCategory];

    if (prices != null) {
      return prices.entries
          .map(
            (entry) => ProductVariant(
              label: entry.key,
              price: entry.value,
            ),
          )
          .toList();
    }

    // Fallback if the product has custom variants in Firestore.
    return product.variants;
  }

  // ADD PRODUCT TO CART

  Future<void> _add(Product product) async {
    if (product.stock <= 0) {
      _showMessage(
        'Sorry, this product is out of stock.',
        color: Colors.red,
      );
      return;
    }

    ProductVariant? selected;

    if (product.category == 'Drinks') {
      selected = await _chooseDrinkSize(product);

      if (selected == null || !mounted) return;
    } else if (product.category == 'Rice Meals') {
      selected = await _chooseRiceAddons(product);

      if (selected == null || !mounted) return;
    } else if (product.hasVariants) {
      selected = await _chooseVariant(product);

      if (selected == null || !mounted) return;
    }

    final variant = selected?.label ?? '';
    final price = selected?.price ?? product.price;

    final key = '${product.id}::$variant';
    final current = _cart[key]?.quantity ?? 0;

    if (current >= product.stock) {
      _showMessage(
        'Only ${product.stock} ${product.name} available.',
        color: Colors.orange,
      );
      return;
    }

    _refresh(() {
      if (_cart.containsKey(key)) {
        _cart[key]!.quantity++;
      } else {
        _cart[key] = _CartLine(
          product: product,
          variant: variant,
          price: price,
        );
      }
    });

    _showMessage(
      '${product.name} ($variant) added to cart',
      color: Colors.green,
    );
  }

  // CHOOSE DRINK SIZE

  Future<ProductVariant?> _chooseDrinkSize(
    Product product,
  ) async {
    final variants = _getDrinkVariants(product);

    if (variants.isEmpty) {
      _showMessage(
        'No drink sizes available for this product.',
        color: Colors.red,
      );
      return null;
    }

    return showModalBottomSheet<ProductVariant>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: _brown,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.subCategory,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Choose your drink size',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                ...variants.map(
                  (variant) => Card(
                    elevation: 0,
                    color: const Color(0xFFFFF9E8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.local_cafe,
                        color: _brown,
                      ),
                      title: Text(
                        variant.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Text(
                        '₱${variant.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _brown,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx, variant);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // RICE MEAL ADD-ONS

  Future<ProductVariant?> _chooseRiceAddons(
    Product product,
  ) async {
    bool extraRice = false;
    bool egg = false;

    return showModalBottomSheet<ProductVariant>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final addonPrice =
                (extraRice ? Product.extraRicePrice : 0) +
                (egg ? Product.extraEggPrice : 0);

            final totalPrice = product.price + addonPrice;

            final selectedAddons = <String>[
              if (extraRice) 'Extra Rice',
              if (egg) 'Egg',
            ];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Base price: ₱${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Customize your rice meal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: extraRice,
                      title: const Text('Extra Rice'),
                      subtitle: const Text('+₱20.00'),
                      activeColor: _brown,
                      onChanged: (value) {
                        setModalState(() {
                          extraRice = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: egg,
                      title: const Text('Egg'),
                      subtitle: const Text('+₱15.00'),
                      activeColor: _brown,
                      onChanged: (value) {
                        setModalState(() {
                          egg = value ?? false;
                        });
                      },
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total price',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₱${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: _brown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _yellow,
                          foregroundColor: _brown,
                          padding: const EdgeInsets.all(15),
                        ),
                        onPressed: () {
                          Navigator.pop(
                            ctx,
                            ProductVariant(
                              label: selectedAddons.join(' + '),
                              price: totalPrice,
                            ),
                          );
                        },
                        child: const Text(
                          'ADD TO CART',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // CHICKEN WINGS VARIANTS

  Future<ProductVariant?> _chooseVariant(Product product) async {
    return showModalBottomSheet<ProductVariant>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (product.subCategory.isNotEmpty)
                Text(
                  product.subCategory,
                  style: const TextStyle(color: Colors.black54),
                ),
              const SizedBox(height: 12),
              const Text(
                'Choose serving',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...product.variants.map(
                (variant) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(variant.label),
                  trailing: Text(
                    '₱${variant.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _brown,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, variant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CHANGE CART QUANTITY

  void _changeQty(String key, int delta) {
    final line = _cart[key];
    if (line == null) return;

    final next = line.quantity + delta;

    if (next <= 0) {
      _refresh(() => _cart.remove(key));
      return;
    }

    if (next > line.product.stock) {
      _showMessage(
        'Only ${line.product.stock} ${line.product.name} available.',
        color: Colors.orange,
      );
      return;
    }

    _refresh(() => line.quantity = next);
  }

  // VALIDATE STOCK

  Future<void> _validateCartStock() async {
  final collection =
      FirebaseFirestore.instance.collection('products');

  for (final line in _cart.values) {
    final doc = await collection.doc(line.product.id).get();

    // Reject products that no longer exist in Firestore.
    if (!doc.exists || doc.data() == null) {
      throw Exception(
        '${line.product.name} is no longer available.',
      );
    }

    final data = doc.data()!;

    final stock = _integer(data['stock']);

    if (stock <= 0) {
      throw Exception('${line.product.name} is out of stock.');
    }

    if (line.quantity > stock) {
      throw Exception(
        'Only $stock ${line.product.name} available. '
        'Update your cart.',
      );
    }

    final category =
        (data['category'] ?? '').toString().trim();

    final subCategory =
        (data['subCategory'] ?? data['drinkType'] ?? '')
            .toString()
            .trim();

    final basePrice = _number(data['price']);

    double expectedPrice = basePrice;

    // DRINK PRICE VALIDATION
    if (category.toLowerCase() == 'drinks' ||
        Product.drinkTypes.any(
          (type) => type.toLowerCase() == category.toLowerCase(),
        ) ||
        category == 'Italian Series') {
      final drinkType = category.toLowerCase() == 'drinks'
          ? subCategory
          : category == 'Italian Series'
              ? 'Italian Soda'
              : category;

      final prices = _drinkSizePrices[drinkType];

      if (prices != null) {
        expectedPrice = prices[line.variant] ?? -1;
      } else {
        final variants = data['variants'];

        if (variants is List) {
          final matching = variants.whereType<Map>().where(
            (variant) =>
                (variant['label'] ?? '').toString() ==
                line.variant,
          );

          if (matching.isNotEmpty) {
            expectedPrice = _number(matching.first['price']);
          } else {
            expectedPrice = -1;
          }
        } else {
          expectedPrice = -1;
        }
      }
    }

    // RICE MEAL ADD-ON VALIDATION
    else if (category == 'Rice Meals') {
      final addons = line.variant.isEmpty
          ? <String>[]
          : line.variant.split(' + ');

      expectedPrice = basePrice;

      if (addons.contains('Extra Rice')) {
        expectedPrice += Product.extraRicePrice;
      }

      if (addons.contains('Egg')) {
        expectedPrice += Product.extraEggPrice;
      }
    }

    // OTHER PRODUCT VARIANTS, INCLUDING CHICKEN WINGS
    else {
      final variants = data['variants'];

      if (line.variant.isNotEmpty && variants is List) {
        final matching = variants.whereType<Map>().where(
          (variant) =>
              (variant['label'] ?? '').toString() ==
              line.variant,
        );

        if (matching.isNotEmpty) {
          expectedPrice = _number(matching.first['price']);
        } else {
          expectedPrice = -1;
        }
      }
    }

    if (expectedPrice <= 0) {
      throw Exception(
        'Invalid price or variant for ${line.product.name}.',
      );
    }

    if ((line.price - expectedPrice).abs() > 0.01) {
      throw Exception(
        'The price of ${line.product.name} has changed. '
        'Please update your cart.',
      );
    }
  }
}

  // GCASH RECEIPT PICKER

  Future<void> _pickGcashReceipt() async {
    try {
      final selectedFile = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (selectedFile == null) return;

      final bytes = await selectedFile.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('Unable to read the selected image.');
      }

      if (bytes.length > 700 * 1024) {
        throw Exception(
          'Screenshot is too large. Select an image smaller than 700 KB.',
        );
      }

      final extension =
          selectedFile.name.split('.').last.toLowerCase();

      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };

      if (!mounted) return;

      _refresh(() {
        _gcashReceipt = bytes;
        _gcashReceiptName = selectedFile.name;
        _gcashReceiptContentType = contentType;
      });

      _showMessage(
        'Payment screenshot selected successfully.',
        color: Colors.green,
      );
    } catch (error) {
      debugPrint('PICK RECEIPT ERROR: $error');

      _showMessage(
        'Could not select image: $error',
        color: Colors.red,
      );
    }
  }

  // GCASH RECEIPT DATA

  Future<String> _uploadGcashReceipt(String userId) async {
    final bytes = _gcashReceipt;

    if (bytes == null || bytes.isEmpty) {
      throw Exception(
        'Please upload your GCash payment screenshot.',
      );
    }

    _refresh(() => _uploadingReceipt = true);

    try {
      if (bytes.length > 700 * 1024) {
        throw Exception(
          'Screenshot is too large. Select an image smaller than 700 KB.',
        );
      }

      debugPrint(
        'GCASH RECEIPT: $userId (${bytes.length} bytes)',
      );

      return 'data:$_gcashReceiptContentType;base64,'
          '${base64Encode(bytes)}';
    } finally {
      if (mounted) {
        _refresh(() => _uploadingReceipt = false);
      }
    }
  }

  // CHECKOUT

  Future<void> _checkout() async {
  if (_cart.isEmpty || _checkingOut) return;

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    _showMessage('Please log in first.');
    return;
  }

  if (_paymentMethod == 'GCash' && _gcashReceipt == null) {
    _showMessage(
      'Please upload your GCash payment screenshot first.',
      color: Colors.red,
    );
    return;
  }

  _refresh(() => _checkingOut = true);

  try {
    await _validateCartStock();

    var address = '';
    var phone = '';
    var location = '';
    var fee = 0.0;

    if (_orderType == 'Delivery') {
      final profile =
          await DatabaseService().getUserProfile(user.uid);

      address = (profile['address'] ?? '').toString().trim();
      phone = (profile['phone'] ?? '').toString().trim();

      if (mounted) {
        _refresh(() => _homeProfileData = profile);
      }

      if (address.isEmpty || phone.isEmpty) {
        if (mounted) {
          _refresh(() => _tab = 3);
        }

        throw Exception(
          'Complete your address and contact number in Profile first.',
        );
      }

      if (_deliveryLocation == null ||
          !_deliveryRates.containsKey(_deliveryLocation)) {
        throw Exception('Please select your delivery location.');
      }

      location = _deliveryLocation!;
      fee = _deliveryRates[location]!;
    }

    final items = _cart.values.map((line) {
      final isRiceMeal = line.product.category == 'Rice Meals';
      final isDrink = line.product.category == 'Drinks';

      final addOns = isRiceMeal && line.variant.isNotEmpty
          ? line.variant.split(' + ')
          : <String>[];

      final addOnPrice = isRiceMeal
          ? line.price - line.product.price
          : 0.0;

      return <String, dynamic>{
        'productId': line.product.id,
        'name': line.product.name,
        'category': line.product.category,
        'subCategory': line.product.subCategory,
        'variant': line.variant,
        'size': isDrink ? line.variant : '',
        'basePrice': isRiceMeal || isDrink
            ? line.product.price
            : line.price,
        'addOns': addOns,
        'addOnPrice': addOnPrice,
        'price': line.price,
        'quantity': line.quantity,
        'subtotal': line.price * line.quantity,
      };
    }).toList();

    if (items.isEmpty) {
      throw Exception('Your cart has no valid products.');
    }

    final subtotal = items.fold<double>(
  0,
  (runningTotal, item) =>
      runningTotal + (item['subtotal'] as num).toDouble(),
);

    final total = subtotal + fee;

    final receipt = _paymentMethod == 'GCash'
        ? await _uploadGcashReceipt(user.uid)
        : '';

    // Reuse the same request ID when retrying the same submission.
    final orderService = DatabaseService();
    _pendingOrderId ??= orderService.newOrderId();

    await orderService.placeOrder(
      requestId: _pendingOrderId!,
      userId: user.uid,
      email: user.email ?? '',
      items: items,
      subtotal: subtotal,
      deliveryFee: fee,
      deliveryLocation: location,
      total: total,
      orderType: _orderType,
      paymentMethod: _paymentMethod,
      deliveryAddress: address,
      contactNumber: phone,
      receiptUrl: receipt,
    );

    if (!mounted) return;

    _refresh(() {
      _cart.clear();
      _gcashReceipt = null;
      _gcashReceiptName = '';
      _gcashReceiptContentType = 'image/jpeg';
      _pendingOrderId = null;
      _tab = 2;
    });

    _showMessage(
      'Order placed successfully!',
      color: Colors.green,
    );
  } catch (error) {
    debugPrint('CHECKOUT ERROR: $error');

    _showMessage(
      'Checkout failed: ${error.toString().replaceFirst('Exception: ', '')}',
      color: Colors.red,
    );
  } finally {
    if (mounted) {
      _refresh(() => _checkingOut = false);
    }
  }
}

  // MAIN BUILD

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homePage(),
      _cartPage(),
      _ordersPage(),
      _profilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.jpg',
              height: 42,
              width: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                "KK's Burger and More",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: _brown,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: () => _refresh(() => _tab = 1),
            icon: Badge(
              isLabelVisible: _cartCount > 0,
              label: Text('$_cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          _refresh(() => _tab = index);
        },
        indicatorColor: _yellow.withValues(alpha: .45),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _profilePage() {
    return ProfilePage(
      onViewOrders: () => _refresh(() => _tab = 2),
    );
  }
}
