
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

import '../../models/product.dart';
import 'admin_constants.dart';

const Color adminOrange = Color(0xFFFF6B35);

const List<String> productCategories = Product.categories;

const List<String> drinkTypes = [
  'Milk Tea',
  'Ice Blended',
  'Iced Coffee',
  'Fruitea',
  'Yakult Series',
  'Italian Soda',
];

const Map<String, Map<String, double>> drinkSizePrices = {
  'Milk Tea': {
    'Medium': 49,
    'Large': 59,
  },
  'Ice Blended': {
    'Medium': 89,
    'Large': 99,
  },
  'Iced Coffee': {
    'Medium': 79,
    'Large': 89,
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

final List<Map<String, dynamic>> defaultDrinks = [
  // MILK TEA
  {'id': 'drink_milk_classic', 'name': 'Classic Milk Tea', 'type': 'Milk Tea', 'price': 49},
  {'id': 'drink_milk_okinawa', 'name': 'Okinawa Milk Tea', 'type': 'Milk Tea', 'price': 59},
  {'id': 'drink_milk_taro', 'name': 'Taro Milk Tea', 'type': 'Milk Tea', 'price': 59},
  {'id': 'drink_milk_wintermelon', 'name': 'Wintermelon Milk Tea', 'type': 'Milk Tea', 'price': 59},
  {'id': 'drink_milk_hokkaido', 'name': 'Hokkaido Milk Tea', 'type': 'Milk Tea', 'price': 59},
  {'id': 'drink_milk_chocolate', 'name': 'Chocolate Milk Tea', 'type': 'Milk Tea', 'price': 59},
  {'id': 'drink_milk_matcha', 'name': 'Matcha Milk Tea', 'type': 'Milk Tea', 'price': 69},
  {'id': 'drink_milk_cookies', 'name': 'Cookies and Cream Milk Tea', 'type': 'Milk Tea', 'price': 69},
  {'id': 'drink_milk_cheesecake', 'name': 'Cheesecake Milk Tea', 'type': 'Milk Tea', 'price': 69},
  {'id': 'drink_milk_brown_sugar', 'name': 'Brown Sugar Milk Tea', 'type': 'Milk Tea', 'price': 69},

  // ICE BLENDED
  {'id': 'drink_blended_chocolate', 'name': 'Chocolate Ice Blended', 'type': 'Ice Blended', 'price': 59},
  {'id': 'drink_blended_vanilla', 'name': 'Vanilla Ice Blended', 'type': 'Ice Blended', 'price': 59},
  {'id': 'drink_blended_strawberry', 'name': 'Strawberry Ice Blended', 'type': 'Ice Blended', 'price': 59},
  {'id': 'drink_blended_cookies', 'name': 'Cookies and Cream Ice Blended', 'type': 'Ice Blended', 'price': 69},
  {'id': 'drink_blended_mocha', 'name': 'Mocha Ice Blended', 'type': 'Ice Blended', 'price': 69},
  {'id': 'drink_blended_caramel', 'name': 'Caramel Ice Blended', 'type': 'Ice Blended', 'price': 69},
  {'id': 'drink_blended_matcha', 'name': 'Matcha Ice Blended', 'type': 'Ice Blended', 'price': 69},
  {'id': 'drink_blended_taro', 'name': 'Taro Ice Blended', 'type': 'Ice Blended', 'price': 69},

  // ICED COFFEE
  {'id': 'drink_coffee_americano', 'name': 'Iced Americano', 'type': 'Iced Coffee', 'price': 49},
  {'id': 'drink_coffee_latte', 'name': 'Iced Latte', 'type': 'Iced Coffee', 'price': 59},
  {'id': 'drink_coffee_spanish', 'name': 'Iced Spanish Latte', 'type': 'Iced Coffee', 'price': 69},
  {'id': 'drink_coffee_mocha', 'name': 'Iced Mocha', 'type': 'Iced Coffee', 'price': 69},
  {'id': 'drink_coffee_caramel', 'name': 'Iced Caramel Macchiato', 'type': 'Iced Coffee', 'price': 69},
  {'id': 'drink_coffee_vanilla', 'name': 'Iced Vanilla Latte', 'type': 'Iced Coffee', 'price': 69},
  {'id': 'drink_coffee_hazelnut', 'name': 'Iced Hazelnut Coffee', 'type': 'Iced Coffee', 'price': 69},

  // FRUITEA
  {'id': 'drink_fruitea_blueberry', 'name': 'Blueberry Fruitea', 'type': 'Fruitea', 'price': 49},
  {'id': 'drink_fruitea_strawberry', 'name': 'Strawberry Fruitea', 'type': 'Fruitea', 'price': 49},
  {'id': 'drink_fruitea_green_apple', 'name': 'Green Apple Fruitea', 'type': 'Fruitea', 'price': 49},
  {'id': 'drink_fruitea_lychee', 'name': 'Lychee Fruitea', 'type': 'Fruitea', 'price': 49},
  {'id': 'drink_fruitea_mango', 'name': 'Mango Fruitea', 'type': 'Fruitea', 'price': 49},
  {'id': 'drink_fruitea_passion', 'name': 'Passion Fruit Fruitea', 'type': 'Fruitea', 'price': 59},
  {'id': 'drink_fruitea_peach', 'name': 'Peach Fruitea', 'type': 'Fruitea', 'price': 59},
  {'id': 'drink_fruitea_lemon', 'name': 'Lemon Fruitea', 'type': 'Fruitea', 'price': 49},

  // YAKULT SERIES
  {'id': 'drink_yakult_blueberry', 'name': 'Blueberry Yakult', 'type': 'Yakult Series', 'price': 59},
  {'id': 'drink_yakult_strawberry', 'name': 'Strawberry Yakult', 'type': 'Yakult Series', 'price': 59},
  {'id': 'drink_yakult_green_apple', 'name': 'Green Apple Yakult', 'type': 'Yakult Series', 'price': 59},
  {'id': 'drink_yakult_lychee', 'name': 'Lychee Yakult', 'type': 'Yakult Series', 'price': 59},
  {'id': 'drink_yakult_mango', 'name': 'Mango Yakult', 'type': 'Yakult Series', 'price': 59},
  {'id': 'drink_yakult_passion', 'name': 'Passion Fruit Yakult', 'type': 'Yakult Series', 'price': 69},
  {'id': 'drink_yakult_peach', 'name': 'Peach Yakult', 'type': 'Yakult Series', 'price': 69},

  // ITALIAN SODA
  {'id': 'drink_soda_blueberry', 'name': 'Blueberry Italian Soda', 'type': 'Italian Soda', 'price': 49},
  {'id': 'drink_soda_strawberry', 'name': 'Strawberry Italian Soda', 'type': 'Italian Soda', 'price': 49},
  {'id': 'drink_soda_green_apple', 'name': 'Green Apple Italian Soda', 'type': 'Italian Soda', 'price': 49},
  {'id': 'drink_soda_lychee', 'name': 'Lychee Italian Soda', 'type': 'Italian Soda', 'price': 49},
  {'id': 'drink_soda_mango', 'name': 'Mango Italian Soda', 'type': 'Italian Soda', 'price': 49},
  {'id': 'drink_soda_blue_ocean', 'name': 'Blue Ocean Italian Soda', 'type': 'Italian Soda', 'price': 59},
  {'id': 'drink_soda_raspberry', 'name': 'Raspberry Italian Soda', 'type': 'Italian Soda', 'price': 59},
];

// ============================================================
// PRODUCT MANAGEMENT
// ============================================================

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedDrinkSubCategory = 'All Drinks';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _message(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // IMPORT DEFAULT PRODUCTS

  Future<void> _importDefaultProducts() async {
    try {
      final collection =
          FirebaseFirestore.instance.collection('products');

      int imported = 0;
      int skipped = 0;

      for (final p in Product.menu) {
        final ref = collection.doc(p.id);

        if ((await ref.get()).exists) {
          skipped++;
          continue;
        }

        await ref.set({
          'name': p.name,
          'category': p.category,
          'subCategory': p.subCategory,
          'price': p.price,
          'variants': p.variants.map((v) => v.toMap()).toList(),
          'stock': 200,
          'imageUrl': p.imageUrl,
          'ingredients': p.ingredients,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        imported++;
      }

      for (final drink in defaultDrinks) {
        final ref = collection.doc(drink['id'] as String);

        if ((await ref.get()).exists) {
          skipped++;
          continue;
        }

        final drinkType = drink['type'] as String;
        final prices = drinkSizePrices[drinkType]!;

        await ref.set({
          'name': drink['name'],
          'category': 'Drinks',
          'subCategory': drinkType,
          'drinkType': drinkType,
          'price': prices['Medium'],
          'variants': [
            {
              'label': 'Medium',
              'price': prices['Medium'],
            },
            {
              'label': 'Large',
              'price': prices['Large'],
            },
          ],
          'stock': 200,
          'imageUrl': '',
          'ingredients': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        imported++;
      }

      if (!mounted) return;

      _message(
        'Import complete! $imported imported, $skipped already existing.',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      _message('Import failed: $e', Colors.red);
    }
  }

  // ADD / EDIT PRODUCT

  Future<void> _form({
    String? id,
    Map<String, dynamic>? data,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProductForm(
        id: id,
        data: data,
      ),
    );

    if (saved == true && mounted) {
      _message(
        id == null
            ? 'Product added successfully!'
            : 'Product updated successfully!',
        Colors.green,
      );
    }
  }

  // DELETE PRODUCT

  Future<void> _delete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Delete Product?',
          style: TextStyle(
            color: adminBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(id)
          .delete();

      if (!mounted) return;
      _message('Product deleted successfully!', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _message('Delete failed: $e', Colors.red);
    }
  }

  // UPDATE STOCK

  Future<void> _updateStock(
    String id,
    String name,
    int currentStock,
  ) async {
    final controller = TextEditingController(
      text: currentStock.toString(),
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Update Stock',
          style: TextStyle(
            color: adminBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Stock Quantity',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            validator: (value) {
              final number = int.tryParse(value ?? '');

              if (number == null || number < 0) {
                return 'Enter a valid quantity';
              }

              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: adminYellow,
              foregroundColor: adminBrown,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  ctx,
                  int.parse(controller.text.trim()),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(id)
          .update({
        'stock': result,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _message('$name stock updated!', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _message('Stock update failed: $e', Colors.red);
    }
  }

  // STATISTIC CARD

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: adminBrown,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MAIN CATEGORY FILTERS

  Widget _categoryFilters() {
    final categories = ['All', ...Product.categories];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 45,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = _selectedCategory == category;

              return ChoiceChip(
                label: Text(category),
                selected: selected,
                showCheckmark: false,
                selectedColor: adminYellow,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected
                      ? adminYellow
                      : Colors.grey.shade300,
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? adminBrown
                      : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category;

                    if (category != 'Drinks') {
                      _selectedDrinkSubCategory = 'All Drinks';
                    }
                  });
                },
              );
            },
          ),
        ),
        if (_selectedCategory == 'Drinks') ...[
          const SizedBox(height: 12),
          const Text(
            'Drink Subcategories',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: adminBrown,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: drinkTypes.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = index == 0
                    ? 'All Drinks'
                    : drinkTypes[index - 1];

                final selected =
                    _selectedDrinkSubCategory == type;

                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: adminBrown,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected
                        ? adminBrown
                        : Colors.grey.shade300,
                  ),
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : adminBrown,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedDrinkSubCategory = type;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // PRODUCT IMAGE

  Widget _productImage(String image) {
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(
            Icons.fastfood,
            size: 45,
            color: Colors.grey,
          ),
        ),
      );
    }

    return const Center(
      child: Icon(
        Icons.fastfood,
        size: 45,
        color: Colors.grey,
      ),
    );
  }

  // PRODUCT CARD

  Widget _productCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final p = doc.data();

    final name = (p['name'] ?? 'Unnamed').toString();
    final category = (p['category'] ?? '').toString();
    final subtype = (p['subCategory'] ?? '').toString();
    final image = (p['imageUrl'] ?? '').toString();

    final stock = (p['stock'] as num?)?.toInt() ?? 0;
    final variants = (p['variants'] as List?) ?? [];

    final priceText = variants.isEmpty
        ? '₱${p['price'] ?? 0}'
        : variants.map((v) {
            final item = Map<String, dynamic>.from(v as Map);
            return '${item['label']}: ₱${item['price']}';
          }).join('\n');

    final available = stock > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 145,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: const Color(0xFFF4F0E9),
                  child: _productImage(image),
                ),
                Positioned(
                  top: 9,
                  left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: available
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      available ? 'Available' : 'Out of Stock',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: const CircleBorder(),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert,
                        color: adminBrown,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _form(id: doc.id, data: p);
                        } else if (value == 'delete') {
                          _delete(doc.id, name);
                        } else if (value == 'stock') {
                          _updateStock(doc.id, name, stock);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 19),
                              SizedBox(width: 9),
                              Text('Edit Product'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'stock',
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 19),
                              SizedBox(width: 9),
                              Text('Update Stock'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 19,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'Delete Product',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: adminBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtype.isEmpty ? category : '$category • $subtype',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    priceText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: adminOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Divider(
                    height: 13,
                    color: Colors.grey.shade200,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: available ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Stock: $stock',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _updateStock(
                          doc.id,
                          name,
                          stock,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: adminBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MAIN SCREEN

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: adminCream,
      appBar: AppBar(
        backgroundColor: adminYellow,
        foregroundColor: adminBrown,
        elevation: 0,
        title: const Text(
          'Manage Products',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: adminOrange,
        foregroundColor: Colors.white,
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading products:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: adminYellow,
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final total = docs.length;

          final available = docs.where((doc) {
            final stock = (doc.data()['stock'] as num?) ?? 0;
            return stock > 0;
          }).length;

          final out = total - available;

          final filteredDocs = docs.where((doc) {
            final p = doc.data();

            final name = (p['name'] ?? '').toString().toLowerCase();
            final category = (p['category'] ?? '').toString();
            final subtype = (p['subCategory'] ?? '').toString();

            final query = _searchQuery.toLowerCase();

            final matchesSearch =
                name.contains(query) ||
                category.toLowerCase().contains(query) ||
                subtype.toLowerCase().contains(query);

            final matchesCategory =
                _selectedCategory == 'All' ||
                category == _selectedCategory;

            final matchesDrinkSubCategory =
                _selectedCategory != 'Drinks' ||
                _selectedDrinkSubCategory == 'All Drinks' ||
                subtype.toLowerCase() ==
                    _selectedDrinkSubCategory.toLowerCase();

            return matchesSearch &&
                matchesCategory &&
                matchesDrinkSubCategory;
          }).toList();

          filteredDocs.sort((a, b) {
            final nameA = (a.data()['name'] ?? '').toString();
            final nameB = (b.data()['name'] ?? '').toString();
            return nameA.compareTo(nameB);
          });

          final sectionTitle = _selectedCategory == 'Drinks' &&
                  _selectedDrinkSubCategory != 'All Drinks'
              ? _selectedDrinkSubCategory
              : _selectedCategory == 'All'
                  ? 'All Products'
                  : _selectedCategory;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: adminBrown,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "KK's Burger and More",
                            style: TextStyle(
                              color: adminYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Manage your menu and product inventory.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.restaurant_menu,
                      size: 43,
                      color: adminYellow,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Product Overview',
                style: TextStyle(
                  color: adminBrown,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  _statCard(
                    title: 'Total Products',
                    value: '$total',
                    icon: Icons.fastfood,
                    color: adminBrown,
                  ),
                  const SizedBox(width: 9),
                  _statCard(
                    title: 'Available',
                    value: '$available',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 9),
                  _statCard(
                    title: 'Out of Stock',
                    value: '$out',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              const Text(
                'Our Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: adminBrown,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              _categoryFilters(),

              const SizedBox(height: 17),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sectionTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: adminBrown,
                      ),
                    ),
                  ),
                  Text(
                    '${filteredDocs.length} products',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.fastfood_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No products yet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: adminBrown,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _importDefaultProducts,
                        icon: const Icon(Icons.download),
                        label: const Text('Import Default Menu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: adminYellow,
                          foregroundColor: adminBrown,
                        ),
                      ),
                    ],
                  ),
                )
              else if (filteredDocs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 45,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No matching products found.',
                        style: TextStyle(color: adminBrown),
                      ),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth >= 650 ? 3 : 2;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDocs.length,
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio:
                            constraints.maxWidth >= 650 ? 0.78 : 0.70,
                      ),
                      itemBuilder: (context, index) {
                        return _productCard(filteredDocs[index]);
                      },
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// PRODUCT FORM
// ============================================================

class _ProductForm extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? data;

  const _ProductForm({
    this.id,
    this.data,
  });

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _key = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _name;
  late final TextEditingController _ingredients;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _subCategory;
  late final TextEditingController _variants;
  late final TextEditingController _mediumPrice;
  late final TextEditingController _largePrice;

  String _category = 'Burgers';
  String _existingImageUrl = '';

  Uint8List? _selectedImageBytes;
  String _selectedImageName = '';
 

  bool _saving = false;
  String? _error;
  double _uploadProgress = 0;

  bool get _editing => widget.id != null;
  bool get _needsVariants => _category == 'Chicken Wings';
  bool get _isDrink => _category == 'Drinks';

  @override
  void initState() {
    super.initState();

    final d = widget.data ?? {};

    _name = TextEditingController(
      text: d['name']?.toString() ?? '',
    );

    _ingredients = TextEditingController(
      text: d['ingredients']?.toString() ?? '',
    );

    _price = TextEditingController(
      text: d['price']?.toString() ?? '',
    );

    _stock = TextEditingController(
      text: d['stock']?.toString() ?? '200',
    );

    _subCategory = TextEditingController(
      text: d['subCategory']?.toString() ??
          d['drinkType']?.toString() ??
          '',
    );

    _existingImageUrl = d['imageUrl']?.toString() ?? '';

    final rawVariants = (d['variants'] as List?) ?? [];

    _variants = TextEditingController(
      text: rawVariants.map((v) {
        final item = Map<String, dynamic>.from(v as Map);
        return '${item['label']}=${item['price']}';
      }).join('\n'),
    );

    final c = d['category']?.toString();

    if (Product.categories.contains(c)) {
      _category = c!;
    }

    // LOAD EXISTING DRINK PRICES

    final savedPrices = <String, double>{};

    for (final raw in rawVariants) {
      final item = Map<String, dynamic>.from(raw as Map);
      final label = item['label']?.toString() ?? '';
      final value = item['price'];

      if (value is num) {
        savedPrices[label] = value.toDouble();
      } else {
        savedPrices[label] =
            double.tryParse(value.toString()) ?? 0;
      }
    }

    final drinkType = _subCategory.text.trim();
    final defaultPrices = drinkSizePrices[drinkType];

    _mediumPrice = TextEditingController(
      text: savedPrices['Medium']?.toString() ??
          (defaultPrices?['Medium']?.toString() ?? ''),
    );

    _largePrice = TextEditingController(
      text: savedPrices['Large']?.toString() ??
          (defaultPrices?['Large']?.toString() ?? ''),
    );

    if (_category == 'Drinks' &&
        savedPrices.isEmpty &&
        defaultPrices != null) {
      _price.text = _mediumPrice.text;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _ingredients.dispose();
    _price.dispose();
    _stock.dispose();
    _subCategory.dispose();
    _variants.dispose();
    _mediumPrice.dispose();
    _largePrice.dispose();
    super.dispose();
  }

  // SET DRINK PRICES

  void _setDrinkPrices(String drinkType) {
    final prices = drinkSizePrices[drinkType];

    if (prices == null) return;

    _mediumPrice.text = prices['Medium']!.toStringAsFixed(0);
    _largePrice.text = prices['Large']!.toStringAsFixed(0);

    _price.text = _mediumPrice.text;
  }

  // ============================================================
  // PICK AND COMPRESS IMAGE
  // ============================================================

  Future<void> _pickProductImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 100,
      );

      if (picked == null) return;

      final originalBytes = await picked.readAsBytes();

      final decoded = img.decodeImage(originalBytes);

      if (decoded == null) {
        throw Exception('Unable to process selected image.');
      }

      final oriented = img.bakeOrientation(decoded);

      final resized = oriented.width >= oriented.height
          ? img.copyResize(oriented, width: 900)
          : img.copyResize(oriented, height: 900);

      final isPng = resized.numChannels == 4;

      final optimizedBytes = isPng
          ? Uint8List.fromList(img.encodePng(resized))
          : Uint8List.fromList(
              img.encodeJpg(resized, quality: 65),
            );

    

      debugPrint(
        'ORIGINAL IMAGE: '
        '${(originalBytes.length / 1024).toStringAsFixed(2)} KB',
      );

      debugPrint(
        'OPTIMIZED IMAGE: '
        '${(optimizedBytes.length / 1024).toStringAsFixed(2)} KB',
      );

      if (!mounted) return;

      setState(() {
        _selectedImageBytes = optimizedBytes;
        _selectedImageName = isPng ? 'product.png' : 'product.jpg';
        
        _uploadProgress = 0;
        _error = null;
      });
    } catch (e) {
      debugPrint('IMAGE PICKER ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to process image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // UPLOAD IMAGE TO CLOUDINARY
  // ============================================================

  Future<String> _uploadProductImage(String productId) async {
    if (_selectedImageBytes == null) {
      return _existingImageUrl;
    }

    const cloudName = 'aa1poggo';
    const uploadPreset = 'kk_burger_upload';

    final uploadUrl = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    try {
      if (mounted) {
        setState(() {
          _uploadProgress = 0.1;
          _error = 'Uploading product image to Cloudinary...';
        });
      }

      final request = http.MultipartRequest(
        'POST',
        uploadUrl,
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'product_images/$productId';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _selectedImageBytes!,
          filename: _selectedImageName,
        ),
      );

      final streamedResponse = await request.send();

      final responseBody =
          await streamedResponse.stream.bytesToString();

      final dynamic decodedResponse = jsonDecode(responseBody);

      if (decodedResponse is! Map<String, dynamic>) {
        throw Exception('Invalid response received from Cloudinary.');
      }

      if (streamedResponse.statusCode != 200) {
        final errorData = decodedResponse['error'];

        final errorMessage = errorData is Map
            ? errorData['message']?.toString()
            : null;

        throw Exception(
          errorMessage ??
              'Cloudinary upload failed. '
                  'Status: ${streamedResponse.statusCode}',
        );
      }

      final imageUrl = decodedResponse['secure_url']?.toString();

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Cloudinary did not return an image URL.');
      }

      if (mounted) {
        setState(() {
          _uploadProgress = 1;
          _error = 'Image uploaded. Saving product details...';
        });
      }

      debugPrint('CLOUDINARY IMAGE URL: $imageUrl');

      return imageUrl;
    } catch (e) {
      debugPrint('CLOUDINARY UPLOAD ERROR: $e');
      rethrow;
    }
  }

  // ============================================================
  // PARSE CHICKEN WINGS VARIANTS
  // ============================================================

  List<Map<String, dynamic>> _parseVariants() {
    final result = <Map<String, dynamic>>[];

    for (final raw in _variants.text.split('\n')) {
      if (raw.trim().isEmpty) continue;

      final pieces = raw.split('=');

      if (pieces.length != 2) {
        throw const FormatException(
          'Use one option per line: 6 pcs=189',
        );
      }

      final label = pieces[0].trim();
      final price = double.tryParse(pieces[1].trim());

      if (label.isEmpty || price == null || price <= 0) {
        throw const FormatException(
          'Check variant labels and prices.',
        );
      }

      result.add({
        'label': label,
        'price': price,
      });
    }

    if (result.isEmpty) {
      throw const FormatException(
        'Add at least one size/serving option.',
      );
    }

    return result;
  }

  // ============================================================
  // SAVE PRODUCT
  // ============================================================

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = 'Preparing product...';
      _uploadProgress = 0;
    });

    try {
      final collection =
          FirebaseFirestore.instance.collection('products');

      final docRef = _editing
          ? collection.doc(widget.id)
          : collection.doc();

      final stopwatch = Stopwatch()..start();

      // STEP 1: Upload image to Cloudinary

      if (_selectedImageBytes != null) {
        setState(() {
          _error = 'Uploading product image...';
        });
      }

      final imageUrl = await _uploadProductImage(docRef.id);

      debugPrint(
        'IMAGE UPLOAD TIME: ${stopwatch.elapsedMilliseconds} ms',
      );

      // STEP 2: Prepare product data

      if (mounted) {
        setState(() {
          _error = 'Saving product details...';
        });
      }

      final selectedDrinkType =
          _category == 'Drinks' ? _subCategory.text.trim() : '';

      final double savedPrice = _isDrink
          ? double.parse(_mediumPrice.text.trim())
          : double.parse(_price.text.trim());

      final List<Map<String, dynamic>> savedVariants;

      if (_isDrink) {
        savedVariants = [
          {
            'label': 'Medium',
            'price': double.parse(_mediumPrice.text.trim()),
          },
          {
            'label': 'Large',
            'price': double.parse(_largePrice.text.trim()),
          },
        ];
      } else if (_needsVariants) {
        savedVariants = _parseVariants();
      } else {
        savedVariants = [];
      }

      final data = <String, dynamic>{
        'name': _name.text.trim(),
        'category': _category,
        'subCategory': selectedDrinkType,
        'drinkType': selectedDrinkType,
        'ingredients': _category == 'Burgers'
            ? _ingredients.text.trim()
            : '',
        'price': savedPrice,
        'stock': int.parse(_stock.text.trim()),
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'variants': savedVariants,
      };

      // STEP 3: Save to Firestore

      if (_editing) {
        await docRef.update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(data);
      }

      stopwatch.stop();

      debugPrint(
        'TOTAL SAVE TIME: ${stopwatch.elapsedMilliseconds} ms',
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      debugPrint('PRODUCT SAVE ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Failed: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product saving failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  Widget _imagePickerSection() {
    Widget imageWidget;

    if (_selectedImageBytes != null) {
      imageWidget = Image.memory(
        _selectedImageBytes!,
        width: double.infinity,
        height: 170,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return const SizedBox(
            height: 170,
            child: Center(
              child: Icon(
                Icons.broken_image,
                size: 45,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    } else if (_existingImageUrl.isNotEmpty) {
      imageWidget = Image.network(
        _existingImageUrl,
        width: double.infinity,
        height: 170,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return const SizedBox(
            height: 170,
            child: Center(
              child: Icon(
                Icons.broken_image,
                size: 45,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    } else {
      imageWidget = const SizedBox(
        height: 170,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'No product image selected',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: Colors.grey.shade100,
            child: imageWidget,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickProductImage,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(
            _selectedImageBytes != null ||
                    _existingImageUrl.isNotEmpty
                ? 'Change Product Image'
                : 'Choose Product Image',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: adminBrown,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FORM UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          _editing ? 'Edit Product' : 'Add Product',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: adminBrown,
          ),
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Form(
              key: _key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PRODUCT NAME

                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      prefixIcon: Icon(Icons.fastfood),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Enter product name'
                            : null,
                  ),

                  const SizedBox(height: 12),

                  // CATEGORY

                  DropdownButtonFormField<String>(
                    key: ValueKey(_category),
                    initialValue: _category,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: Product.categories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                    onChanged: _saving
                        ? null
                        : (v) {
                            if (v == null) return;

                            setState(() {
                              _category = v;

                              if (_category != 'Drinks') {
                                _subCategory.clear();
                                _mediumPrice.clear();
                                _largePrice.clear();
                              }
                            });
                          },
                  ),

                  // DRINK SUBCATEGORY

                  if (_category == 'Drinks') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'drink_${_subCategory.text}',
                      ),
                      initialValue:
                          drinkTypes.contains(_subCategory.text)
                              ? _subCategory.text
                              : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Drink Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_drink),
                      ),
                      items: drinkTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: _saving
                          ? null
                          : (v) {
                              if (v == null) return;

                              setState(() {
                                _subCategory.text = v;
                                _setDrinkPrices(v);
                              });
                            },
                      validator: (v) =>
                          v == null || v.isEmpty
                              ? 'Select a drink category'
                              : null,
                    ),
                  ],

                  // BURGER INGREDIENTS

                  if (_category == 'Burgers') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ingredients,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ingredients',
                        hintText:
                            'Example: Patty, Cheese, Lettuce, Tomato',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.restaurant),
                      ),
                    ),
                  ],

                  // CHICKEN WINGS VARIANTS

                  if (_needsVariants) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _variants,
                      minLines: 3,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Size / Serving and Price',
                        hintText: '6 pcs=189\n12 pcs=299',
                        helperText:
                            'One option per line. Example: 6 pcs=189',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter at least one variant'
                              : null,
                    ),
                  ],

                  // DRINK MEDIUM PRICE

                  if (_isDrink) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _mediumPrice,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Medium Price (₱)',
                        prefixIcon: Icon(Icons.local_drink),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _price.text = value;
                      },
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());

                        return n == null || n <= 0
                            ? 'Enter a valid Medium price'
                            : null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // DRINK LARGE PRICE

                    TextFormField(
                      controller: _largePrice,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Large Price (₱)',
                        prefixIcon: Icon(Icons.local_drink_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());

                        return n == null || n <= 0
                            ? 'Enter a valid Large price'
                            : null;
                      },
                    ),
                  ],

                  // REGULAR PRODUCT PRICE

                  if (!_isDrink) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: _needsVariants
                            ? 'Base Price (₱)'
                            : 'Price (₱)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(
                          Icons.payments_outlined,
                        ),
                      ),
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());

                        return n == null || n <= 0
                            ? 'Enter a valid price'
                            : null;
                      },
                    ),
                  ],

                  const SizedBox(height: 12),

                  // STOCK

                  TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.inventory_2_outlined,
                      ),
                    ),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());

                      return n == null || n < 0
                          ? 'Enter a valid stock quantity'
                          : null;
                    },
                  ),

                  const SizedBox(height: 16),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Product Image',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: adminBrown,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  _imagePickerSection(),

                  // UPLOAD PROGRESS

                  if (_saving && _selectedImageBytes != null) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: adminOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: adminYellow,
              foregroundColor: adminBrown,
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _editing ? 'Save Changes' : 'Add Product',
                  ),
          ),
        ],
      ),
    );
  }
}
