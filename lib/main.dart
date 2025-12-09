import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF6A1B9A); // deep purple
    final scheme = ColorScheme.fromSeed(seedColor: seedColor);

    return MaterialApp(
      title: 'Swiggy',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF8E1), // warm light background
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.primary,
          centerTitle: true,
          elevation: 2,
          foregroundColor: scheme.onPrimary,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<MenuItem> _items = [];

  void _showAddDialog() {
    final nameCtl = TextEditingController();
    final priceCtl = TextEditingController();
    final descCtl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: priceCtl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
            TextField(controller: descCtl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtl.text.trim();
              final price = double.tryParse(priceCtl.text) ?? 0.0;
              final desc = descCtl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _items.add(MenuItem(name: name, price: price, description: desc));
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swiggy'),
        backgroundColor: colorScheme.primary,
      ),
      body: _items.isEmpty
          ? Center(
              child: Text(
                'No menu items yet. Tap + to add.',
                style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => setState(() => _items.removeAt(index)),
                  child: Card(
                    color: colorScheme.surfaceContainerHighest,
                    child: ListTile(
                      title: Text(item.name, style: TextStyle(color: colorScheme.onSurface)),
                      subtitle: item.description.isNotEmpty ? Text(item.description) : null,
                      trailing: Text('\u20B9${item.price.toStringAsFixed(2)}', style: TextStyle(color: colorScheme.primary)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class MenuItem {
  MenuItem({required this.name, required this.price, this.description = ''}) : id = DateTime.now().microsecondsSinceEpoch.toString();
  final String id;
  final String name;
  final double price;
  final String description;
}

