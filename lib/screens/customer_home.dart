import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/favorites_service.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'product_details_screen.dart';
import 'profile_screen.dart';

class CustomerHome extends StatefulWidget {
  final AppUser user;
  const CustomerHome({super.key, required this.user});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  static const categories = ['الكل', 'موبايلات', 'سماعات', 'لابتوب', 'إكسسوارات'];
  String _selectedCategory = 'الكل';
  String _query = '';
  bool _onlyFavorites = false;

  List<Product> _filter(List<Product> all, Set<String> favIds) {
    return all.where((p) {
      final matchCategory =
          _selectedCategory == 'الكل' || p.category == _selectedCategory;
      final matchQuery =
      p.name.toLowerCase().contains(_query.trim().toLowerCase());
      final matchFav = !_onlyFavorites || favIds.contains(p.id);
      return matchCategory && matchQuery && matchFav;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TechZone'),
        actions: [
          StreamBuilder<int>(
            stream: CartService.instance.countStream(),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_cart),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CartScreen(user: widget.user)),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(_onlyFavorites ? Icons.favorite : Icons.favorite_border),
            tooltip: 'المفضلة',
            onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'طلباتي',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProfileScreen(user: widget.user)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: AuthService.instance.logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'ابحث عن منتج...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // التصنيفات
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = categories[i];
                return ChoiceChip(
                  label: Text(c),
                  selected: _selectedCategory == c,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                );
              },
            ),
          ),
          // المنتجات
          Expanded(
            child: StreamBuilder<Set<String>>(
              stream: FavoritesService.instance.favoriteIdsStream(),
              builder: (context, favSnap) {
                final favIds = favSnap.data ?? <String>{};
                return StreamBuilder<List<Product>>(
                  stream: ProductService.instance.productsStream(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return const Center(
                          child: Text('حصل خطأ في تحميل المنتجات'));
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final products = _filter(snap.data!, favIds);
                    if (products.isEmpty) {
                      return Center(
                        child: Text(_onlyFavorites
                            ? 'مفيش منتجات في المفضلة'
                            : 'مفيش منتجات مطابقة'),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, i) {
                        final p = products[i];
                        final isFav = favIds.contains(p.id);
                        return ProductCard(
                          product: p,
                          isFavorite: isFav,
                          onFavoriteTap: () =>
                              FavoritesService.instance.toggle(p.id, isFav),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailsScreen(productId: p.id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}