
part of 'main_screen.dart';

const List<String> _drinkSubCategories = [
  'All Drinks',
  'Milk Tea',
  'Ice Blended',
  'Iced Coffee',
  'Fruitea',
  'Yakult Series',
  'Italian Soda',
];

const Map<String, String> _burgerIngredientsById = {
  'burger_classic': 'Patty, Veggies',
  'burger_cheesy': 'Patty, Veggies, Sliced Cheese and Cheese Sauce',
  'burger_with_egg': 'Patty, Egg and Veggies',
  'burger_ham_egg': 'Patty, Ham, Egg and Veggies',
  'burger_bounty':
      'Patty, Ham, Egg, Veggies, Sliced Cheese and Cheese Sauce',
  'burger_double_cheesy':
      'Double Patty, Double Sliced Cheese, Veggies and Cheese Sauce',
  'burger_rasher':
      'Patty, Bacon, Mushrooms, Sliced Cheese and Cheese Sauce',
  'burger_aloha':
      'Patty, Ham, Pineapple, Veggies, Sliced Cheese and Cheese Sauce',
  'burger_knyx_bomb':
      'Double Patty, Double Sliced Cheese, Ham, Pineapple, Veggies, Onion, Cheese Bomb and Bacon Bits',
  'burger_kzy':
      'Double Patty, Ham, Egg, Bacon, Veggies, Double Sliced Cheese and Cheese Sauce',
  'burger_peppy':
      'Patty, Caramelized Onion and Mushroom, Veggies, Tomato and Sliced Cheese',
};

const Map<String, String> _burgerIngredientsByName = {
  'CLASSIC BURGER': 'Patty, Veggies',
  'CHEESY BURGER': 'Patty, Veggies, Sliced Cheese and Cheese Sauce',
  'BURGER W/ EGG': 'Patty, Egg and Veggies',
  'HAM & EGG': 'Patty, Ham, Egg and Veggies',
  'BOUNTY BURGER':
      'Patty, Ham, Egg, Veggies, Sliced Cheese and Cheese Sauce',
  'DOUBLE CHEESY':
      'Double Patty, Double Sliced Cheese, Veggies and Cheese Sauce',
  'RASHER BURGER':
      'Patty, Bacon, Mushrooms, Sliced Cheese and Cheese Sauce',
  'ALOHA BURGER':
      'Patty, Ham, Pineapple, Veggies, Sliced Cheese and Cheese Sauce',
  'KNYX BOMB':
      'Double Patty, Double Sliced Cheese, Ham, Pineapple, Veggies, Onion, Cheese Bomb and Bacon Bits',
  'KZY BURGER':
      'Double Patty, Ham, Egg, Bacon, Veggies, Double Sliced Cheese and Cheese Sauce',
  'PEPPY BURGER':
      'Patty, Caramelized Onion and Mushroom, Veggies, Tomato and Sliced Cheese',
};

extension _MainScreenHome on _MainScreenState {
  Widget _homePage() {
    final categories = ['All', ...Product.categories];
    final products = _filteredProducts;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _yellow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final username =
                    snapshot.data?['username']?.toString() ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username.isNotEmpty
                          ? 'WELCOME, @$username!'
                          : 'WELCOME!',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Good food, great mood!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _brown,
                      ),
                    ),
                    const Text(
                      'Burgers • Snacks • Wings • Rice Meals • Drinks',
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) {
                _refresh(() {
                  _search = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search your favorite food...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _storeLocationCard(),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              children: categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    selectedColor: _yellow,
                    onSelected: (_) {
                      _refresh(() {
                        _category = category;
                        _drinkSubCategory = 'All Drinks';
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        if (_category == 'Drinks')
          SliverToBoxAdapter(
            child: SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                children: _drinkSubCategories.map((subCategory) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(subCategory),
                      selected: _drinkSubCategory == subCategory,
                      selectedColor: const Color(0xFFFFE08A),
                      backgroundColor: Colors.white,
                      onSelected: (_) {
                        _refresh(() {
                          _drinkSubCategory = subCategory;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        if (_loadingProducts && _products.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_productError != null && _products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not sync products:\n$_productError',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else if (products.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('No products available.'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _productCard(products[index]);
                },
                childCount: products.length,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: .55,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _storeLocationCard() {
    const storeAddress =
        'Brgy. 0262 National Road, Bilibiran, Binangonan, 1940 Rizal';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _yellow.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _yellow.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: _brown,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KK's Burger Pag-asa",
                      style: TextStyle(
                        color: _brown,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Store Information',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '8 AM – 9 PM',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: _brown,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _brown,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      storeAddress,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: _brown,
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'Daily: 8:00 AM – 9:00 PM',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final mapUri = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query='
                  '${Uri.encodeComponent(storeAddress)}',
                );

                try {
                  final opened = await launchUrl(
                    mapUri,
                    mode: LaunchMode.externalApplication,
                  );

                  if (!opened && mounted) {
                    _showMessage('Could not open Google Maps.');
                  }
                } catch (_) {
                  if (mounted) {
                    _showMessage('Could not open Google Maps.');
                  }
                }
              },
              icon: const Icon(Icons.directions_rounded),
              label: const Text('VIEW STORE ON GOOGLE MAPS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _brown,
                side: const BorderSide(color: _yellow, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(Product p) {
    final image = p.imageUrl.trim();
    final isOut = p.stock <= 0;
    final isDrink = p.category == 'Drinks';

    final ImageProvider provider = image.startsWith('http')
        ? NetworkImage(image)
        : AssetImage(
            image.isEmpty ? 'assets/images/logo.jpg' : image,
          );

    final drinkPrices = _drinkSizePrices[p.subCategory];

    final List<double> prices;

if (isDrink && drinkPrices != null) {
  prices = drinkPrices.values.toList();
} else {
  prices = p.variants.map((variant) => variant.price).toList();
}

prices.sort();

    final priceText = isDrink && prices.isNotEmpty
        ? '₱${prices.first.toStringAsFixed(2)} - ₱${prices.last.toStringAsFixed(2)}'
        : p.hasVariants
            ? 'From ₱${prices.first.toStringAsFixed(2)}'
            : '₱${p.price.toStringAsFixed(2)}';

    final savedIngredients = p.ingredients.trim();

    final ingredients = p.category == 'Burgers'
        ? (savedIngredients.isNotEmpty
            ? savedIngredients
            : _burgerIngredientsById[p.id] ??
                _burgerIngredientsByName[p.name.trim().toUpperCase()] ??
                '')
        : '';

    final buttonLabel = isOut
        ? 'Out of Stock'
        : isDrink
            ? 'Choose Size'
            : p.category == 'Rice Meals'
                ? 'Customize'
                : p.hasVariants
                    ? 'Choose Option'
                    : 'Add to Cart';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(
                  image: provider,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFFFE9A6),
                      child: const Center(
                        child: Icon(
                          Icons.fastfood,
                          size: 48,
                          color: _brown,
                        ),
                      ),
                    );
                  },
                ),
                if (isOut)
                  Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: const Text(
                      'OUT OF STOCK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 3),
            child: Text(
              p.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _brown,
              ),
            ),
          ),

          if (p.subCategory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                p.subCategory,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ),

          if (ingredients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 3, 10, 0),
              child: Text(
                'Ingredients: $ingredients',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.3,
                  color: Colors.black54,
                ),
              ),
            ),

          const SizedBox(height: 5),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priceText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: _brown,
                  ),
                ),
                Text(
                  isOut ? 'Unavailable' : 'Available: ${p.stock}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOut ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: isOut ? Colors.grey : _yellow,
                  foregroundColor: isOut ? Colors.white : _brown,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: isOut ? null : () => _add(p),
                icon: Icon(
                  isOut
                      ? Icons.remove_shopping_cart
                      : isDrink
                          ? Icons.local_cafe
                          : p.category == 'Rice Meals'
                              ? Icons.tune
                              : Icons.add,
                  size: 18,
                ),
                label: Text(
                  buttonLabel,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
