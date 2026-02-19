import 'package:flutter/material.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFFF6B00); // vibrant orange (Swiggy-like)
    final scheme = ColorScheme.fromSeed(seedColor: seedColor);

    return MaterialApp(
      title: 'Swiggy',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), // clean light background
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.primary,
          centerTitle: false,
          elevation: 4,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          elevation: 8,
        ),
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  final List<MenuItem> _items = [];
  final List<MenuItem> _favorites = [];
  final List<CartItem> _cart = [];
  final List<Order> _orderHistory = [];
  UserProfile _userProfile = UserProfile();
  final Restaurant _restaurant = Restaurant();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomePage(
        items: _items,
        favorites: _favorites,
        cart: _cart,
        onAddItem: _addItem,
        onAddToCart: _addToCart,
        onToggleFavorite: _toggleFavorite,
        isFavorite: _isFavorite,
      ),
      CartScreen(
        cart: _cart,
        onRemove: _removeFromCart,
        onUpdateQuantity: _updateCartQuantity,
        onCheckout: _checkout,
      ),
      FavoritesScreen(
        favorites: _favorites,
        onRemove: (item) => setState(() => _favorites.remove(item)),
        onAddToCart: _addToCart,
      ),
      OrderHistoryScreen(orders: _orderHistory),
      ProfileScreen(
        userProfile: _userProfile,
        onUpdate: (profile) => setState(() => _userProfile = profile),
        restaurant: _restaurant,
      ),
      RestaurantDetailsScreen(restaurant: _restaurant),
    ];
  }

  void _addItem(MenuItem item) {
    setState(() => _items.add(item));
  }

  void _addToCart(MenuItem item, int quantity, List<String> addOns, String size) {
    setState(() {
      final existingIndex = _cart.indexWhere((ci) =>
          ci.item.id == item.id && ci.size == size && _listEquals(ci.addOns, addOns));
      if (existingIndex != -1) {
        _cart[existingIndex].quantity += quantity;
      } else {
        _cart.add(CartItem(
          item: item,
          quantity: quantity,
          addOns: addOns,
          size: size,
        ));
      }
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() => _cart.remove(item));
  }

  void _updateCartQuantity(CartItem item, int quantity) {
    setState(() {
      final index = _cart.indexOf(item);
      if (index != -1) {
        if (quantity <= 0) {
          _cart.removeAt(index);
        } else {
          _cart[index].quantity = quantity;
        }
      }
    });
  }

  void _toggleFavorite(MenuItem item) {
    setState(() {
      if (_favorites.contains(item)) {
        _favorites.remove(item);
      } else {
        _favorites.add(item);
      }
    });
  }

  bool _isFavorite(MenuItem item) => _favorites.contains(item);

  void _checkout(String paymentMethod) {
    if (_cart.isEmpty) return;

    final order = Order(
      items: List.from(_cart),
      totalPrice: _calculateTotal(),
      paymentMethod: paymentMethod,
      status: 'Confirmed',
    );

    setState(() {
      _orderHistory.add(order);
      _cart.clear();
      _selectedIndex = 3; // Go to order history
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Order placed successfully!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _calculateTotal() {
    return _cart.fold(0, (sum, item) => sum + (item.item.price * item.quantity));
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Restaurant'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<MenuItem> items;
  final List<MenuItem> favorites;
  final List<CartItem> cart;
  final Function(MenuItem) onAddItem;
  final Function(MenuItem, int, List<String>, String) onAddToCart;
  final Function(MenuItem) onToggleFavorite;
  final Function(MenuItem) isFavorite;

  const HomePage({
    super.key,
    required this.items,
    required this.favorites,
    required this.cart,
    required this.onAddItem,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.isFavorite,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _searchCtl = TextEditingController();
  String _selectedCategory = 'All';
  late AnimationController _fabAnimCtl;

  final List<String> _categories = ['All', 'Veg', 'Non-Veg', 'Desserts', 'Beverages'];
  final Map<String, IconData> _categoryIcons = {
    'All': Icons.restaurant_menu,
    'Veg': Icons.eco,
    'Non-Veg': Icons.fastfood,
    'Desserts': Icons.cake,
    'Beverages': Icons.local_drink,
  };

  @override
  void initState() {
    super.initState();
    _fabAnimCtl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
  }

  @override
  void dispose() {
    _fabAnimCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  List<MenuItem> get _filteredItems {
    final query = _searchCtl.text.toLowerCase();
    return widget.items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(query) || item.description.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showAddDialog() {
    final nameCtl = TextEditingController();
    final priceCtl = TextEditingController();
    final descCtl = TextEditingController();
    String selectedCat = 'Veg';
    int selectedRating = 4;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add Menu Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtl,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(Icons.restaurant),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtl,
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtl,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCat,
                  items: _categories.skip(1).map((cat) => DropdownMenuItem(value: cat, child: Row(children: [Icon(_categoryIcons[cat]), const SizedBox(width: 8), Text(cat)]))).toList(),
                  onChanged: (val) => setModalState(() => selectedCat = val ?? 'Veg'),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Rating: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Row(
                        children: List.generate(
                          5,
                          (i) => GestureDetector(
                            onTap: () => setModalState(() => selectedRating = i + 1),
                            child: Icon(Icons.star, color: i < selectedRating ? Colors.amber : Colors.grey, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtl.text.trim();
                final price = double.tryParse(priceCtl.text) ?? 0.0;
                final desc = descCtl.text.trim();
                if (name.isNotEmpty) {
                  widget.onAddItem(MenuItem(
                    name: name,
                    price: price,
                    description: desc,
                    category: selectedCat,
                    rating: selectedRating,
                  ));
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomizationDialog(MenuItem item) {
    int quantity = 1;
    String selectedSize = 'Regular';
    List<String> selectedAddOns = [];

    final addOnOptions = ['Extra Cheese', 'Extra Sauce', 'No Onion', 'No Garlic', 'Spicy'];

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Customize Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Size:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: ['Small', 'Regular', 'Large'].map((size) {
                    final isSelected = size == selectedSize;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedSize = size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            size,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Add-ons:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...addOnOptions.map((addOn) => CheckboxListTile(
                  title: Text(addOn),
                  value: selectedAddOns.contains(addOn),
                  onChanged: (selected) => setModalState(() {
                    if (selected ?? false) {
                      selectedAddOns.add(addOn);
                    } else {
                      selectedAddOns.remove(addOn);
                    }
                  }),
                  dense: true,
                )),
                const SizedBox(height: 16),
                const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setModalState(() => quantity = (quantity - 1).clamp(1, 10)),
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Text(
                        quantity.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setModalState(() => quantity = (quantity + 1).clamp(1, 10)),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                widget.onAddToCart(item, quantity, selectedAddOns, selectedSize);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Added to cart!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              child: const Text('Add to Cart', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Swiggy Restaurant'),
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: TextField(
              controller: _searchCtl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          // Category Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Row(
                      children: [
                        Icon(_categoryIcons[cat], size: 18),
                        const SizedBox(width: 4),
                        Text(cat),
                      ],
                    ),
                    selected: isSelected,
                    backgroundColor: Colors.grey[200],
                    selectedColor: colorScheme.primary,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Menu Items List
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fastfood_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text('Add your first menu item!', style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isFav = widget.isFavorite(item);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey[50]!],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: item.category == 'Veg' ? Colors.green : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isFav ? Icons.favorite : Icons.favorite_border,
                                        color: isFav ? Colors.red : Colors.grey,
                                        size: 24,
                                      ),
                                      onPressed: () => widget.onToggleFavorite(item),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.category,
                                        style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (item.description.isNotEmpty)
                                  Text(
                                    item.description,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ...List.generate(5, (i) => Icon(Icons.star, color: i < item.rating ? Colors.amber : Colors.grey[300], size: 14)),
                                    const Spacer(),
                                    Text(
                                      '\u20B9${item.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _showCustomizationDialog(item),
                                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                                      label: const Text('Add'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Add Item',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}


// ========== SCREENS ==========

class CartScreen extends StatefulWidget {
  final List<CartItem> cart;
  final Function(CartItem) onRemove;
  final Function(CartItem, int) onUpdateQuantity;
  final Function(String) onCheckout;

  const CartScreen({
    super.key,
    required this.cart,
    required this.onRemove,
    required this.onUpdateQuantity,
    required this.onCheckout,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _selectedPayment = 'Credit Card';
  final List<String> _paymentMethods = ['Credit Card', 'Debit Card', 'UPI', 'Cash on Delivery'];

  double _getTotal() {
    return widget.cart.fold(0, (sum, item) => sum + (item.item.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: widget.cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final cartItem = widget.cart[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cartItem.item.name,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Size: ${cartItem.size}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        if (cartItem.addOns.isNotEmpty)
                                          Text(
                                            'Add-ons: ${cartItem.addOns.join(", ")}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\u20B9${(cartItem.item.price * cartItem.quantity).toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => widget.onUpdateQuantity(cartItem, cartItem.quantity - 1),
                                    icon: const Icon(Icons.remove),
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    cartItem.quantity.toString(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => widget.onUpdateQuantity(cartItem, cartItem.quantity + 1),
                                    icon: const Icon(Icons.add),
                                    iconSize: 20,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => widget.onRemove(cartItem),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _paymentMethods.map((method) {
                          final isSelected = method == _selectedPayment;
                          return ChoiceChip(
                            label: Text(method),
                            selected: isSelected,
                            backgroundColor: Colors.grey[200],
                            selectedColor: colorScheme.primary,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                            onSelected: (_) => setState(() => _selectedPayment = method),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\u20B9${_getTotal().toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => widget.onCheckout(_selectedPayment),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<MenuItem> favorites;
  final Function(MenuItem) onRemove;
  final Function(MenuItem, int, List<String>, String) onAddToCart;

  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.onRemove,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(
                                item.description,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\u20B9${item.price.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => onRemove(item),
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => onAddToCart(item, 1, [], 'Regular'),
                              icon: const Icon(Icons.add_shopping_cart, size: 16),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class OrderHistoryScreen extends StatelessWidget {
  final List<Order> orders;

  const OrderHistoryScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${index + 1}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.status,
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map((item) => Text(
                          '${item.item.name} x${item.quantity}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        )),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment: ${order.paymentMethod}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              '\u20B9${order.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onUpdate;
  final Restaurant restaurant;

  const ProfileScreen({
    super.key,
    required this.userProfile,
    required this.onUpdate,
    required this.restaurant,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtl;
  late TextEditingController _emailCtl;
  late TextEditingController _phoneCtl;
  late TextEditingController _addressCtl;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.userProfile.name);
    _emailCtl = TextEditingController(text: widget.userProfile.email);
    _phoneCtl = TextEditingController(text: widget.userProfile.phone);
    _addressCtl = TextEditingController(text: widget.userProfile.address);
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _addressCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtl,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtl,
              decoration: InputDecoration(
                labelText: 'Phone',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtl,
              decoration: InputDecoration(
                labelText: 'Delivery Address',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onUpdate(UserProfile(
                    name: _nameCtl.text,
                    email: _emailCtl.text,
                    phone: _phoneCtl.text,
                    address: _addressCtl.text,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestaurantDetailsScreen extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailsScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.restaurant, size: 100, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              restaurant.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('${restaurant.rating} (${restaurant.reviews} reviews)', style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Address'),
                      subtitle: Text(restaurant.address),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Phone'),
                      subtitle: Text(restaurant.phone),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Hours'),
                      subtitle: Text(restaurant.hours),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.local_shipping),
                      title: const Text('Delivery Time'),
                      subtitle: Text(restaurant.deliveryTime),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.payments),
                      title: const Text('Min Order'),
                      subtitle: Text('\u20B9${restaurant.minOrder}'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              restaurant.description,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== MODELS ==========

class MenuItem {
  MenuItem({
    required this.name,
    required this.price,
    this.description = '',
    this.category = 'Veg',
    this.rating = 4,
  }) : id = DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final int rating;
}

class CartItem {
  CartItem({
    required this.item,
    required this.quantity,
    required this.addOns,
    required this.size,
  });

  final MenuItem item;
  int quantity;
  final List<String> addOns;
  final String size;
}

class Order {
  Order({
    required this.items,
    required this.totalPrice,
    required this.paymentMethod,
    required this.status,
  }) : orderDate = DateTime.now();

  final List<CartItem> items;
  final double totalPrice;
  final String paymentMethod;
  String status;
  final DateTime orderDate;
}

class UserProfile {
  UserProfile({
    this.name = 'Guest User',
    this.email = '',
    this.phone = '',
    this.address = '',
  });

  final String name;
  final String email;
  final String phone;
  final String address;
}

class Restaurant {
  Restaurant()
    : name = 'Swiggy Restaurant',
      rating = 4.5,
      reviews = 128,
      address = '123 Food Street, City Center, Metro City',
      phone = '+91-98765-43210',
      hours = '10:00 AM - 11:00 PM',
      deliveryTime = '30-45 minutes',
      minOrder = '299',
      description = 'Experience authentic culinary delights with our diverse menu featuring Veg, Non-Veg, Desserts, and Beverages. We deliver fresh, delicious food right to your doorstep with utmost care and quality.';

  final String name;
  final double rating;
  final int reviews;
  final String address;
  final String phone;
  final String hours;
  final String deliveryTime;
  final String minOrder;
  final String description;
}
