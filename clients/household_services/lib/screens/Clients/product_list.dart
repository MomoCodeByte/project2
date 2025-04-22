import 'package:flutter/material.dart';
import '../Componets/Login_screen.dart';

class ProductCategoriesScreen extends StatelessWidget {
  const ProductCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Home Products'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement notification logic (maybe fetch from API)
            },
            icon: const Icon(Icons.notifications, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                // TODO: Handle user login/logout through API
                // TODO: Implement login/logout logic

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              icon: const Icon(Icons.login, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Find the perfect products\nfor your home',
                      textAlign: TextAlign.center, // 👈 Add this line
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Search for products...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.teal,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (query) {
                          // TODO: Implement search logic calling backend API with `query`
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Categories Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // TODO: Replace static GridView with FutureBuilder calling categories API
                    // You may fetch the categories like:
                    // Future<List<Category>> fetchCategories() => apiService.getCategories();
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        _buildCategoryCard(
                          context,
                          'Cleaning Supplies',
                          Icons.cleaning_services,
                          Colors.blue.shade100,
                          () {
                            // TODO: Navigate with category ID to products page & fetch category-specific products
                          },
                        ),
                        _buildCategoryCard(
                          context,
                          'Kitchen Appliances',
                          Icons.blender,
                          Colors.orange.shade100,
                          () {},
                        ),
                        _buildCategoryCard(
                          context,
                          'Home Decor',
                          Icons.chair,
                          Colors.green.shade100,
                          () {},
                        ),
                        _buildCategoryCard(
                          context,
                          'Bed & Bath',
                          Icons.king_bed,
                          Colors.purple.shade100,
                          () {},
                        ),
                        _buildCategoryCard(
                          context,
                          'Laundry',
                          Icons.local_laundry_service,
                          Colors.pink.shade100,
                          () {},
                        ),
                        _buildCategoryCard(
                          context,
                          'Smart Home',
                          Icons.wifi,
                          Colors.cyan.shade100,
                          () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Popular Products Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Popular Products',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to popular products screen (fetch all from backend)
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(color: Colors.teal),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // TODO: Replace static list with dynamic API-fetched products
                    // Example:
                    // Future<List<Product>> fetchPopularProducts() => apiService.getPopularProducts();
                    SizedBox(
                      height: 180,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildProductCard(
                            'Premium Vacuum Cleaner',
                            '\$149.99',
                            Icons.cleaning_services,
                            () {
                              // TODO: Navigate to product detail with ID, fetch product data from backend
                            },
                          ),
                          _buildProductCard(
                            'Smart Blender',
                            '\$89.99',
                            Icons.blender,
                            () {},
                          ),
                          _buildProductCard(
                            'Luxury Bed Sheets',
                            '\$59.99',
                            Icons.bed,
                            () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar (likely static, but can also reflect API state, e.g., cart count)
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          // TODO: Implement navigation logic to respective screens
          // Use Navigator.pushNamed or a bottom nav controller
        },
      ),
    );
  }

  // CATEGORY CARD
  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: color.withOpacity(0.8)),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // PRODUCT CARD
  Widget _buildProductCard(
    String title,
    String price,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Center(child: Icon(icon, size: 50, color: Colors.teal)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
