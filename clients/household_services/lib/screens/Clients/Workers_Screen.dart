import 'package:flutter/material.dart';
import '../Componets/Login_screen.dart';

class DomesticWorkersScreen extends StatelessWidget {
  const DomesticWorkersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Domestic Workers'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 4,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement notification logic
            },
            icon: const Icon(Icons.notifications, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                // TODO: Implement login/logout logic
              
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  LoginScreen()),
                );
              },
              icon: const Icon(Icons.login, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Hero Section with Search and Filter
            Container(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Find Skilled Professionals\nfor Your Home',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search for services...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: const Icon(Icons.search, color: Colors.teal),
                              border: InputBorder.none,
                            ),
                            onChanged: (query) {
                              // TODO: Implement search API call
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Filter Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.filter_list, color: Colors.teal),
                          onPressed: () {
                            // TODO: Show filter options or navigate to filter screen
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Services Section
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildServiceCategory('Cleaning', Icons.cleaning_services),
                        _buildServiceCategory('Cooking', Icons.restaurant),
                        _buildServiceCategory('Childcare', Icons.child_care),
                        _buildServiceCategory('Gardening', Icons.yard),
                        _buildServiceCategory('Plumbing', Icons.plumbing),
                        _buildServiceCategory('Electrical', Icons.electrical_services),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Available Workers Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Filter Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Workers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton<String>(
                          underline: Container(),
                          icon: const Icon(Icons.unfold_more, size: 20),
                          value: 'rating',
                          items: const [
                            DropdownMenuItem(
                              value: 'rating',
                              child: Text('Top Rated'),
                            ),
                            DropdownMenuItem(
                              value: 'price_low',
                              child: Text('Price: Low to High'),
                            ),
                            DropdownMenuItem(
                              value: 'price_high',
                              child: Text('Price: High to Low'),
                            ),
                            DropdownMenuItem(
                              value: 'experience',
                              child: Text('Most Experienced'),
                            ),
                          ],
                          onChanged: (value) {
                            // TODO: Call API to sort workers
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Worker List
                    Expanded(
                      child: ListView(
                        children: [
                          _buildWorkerCard(
                            name: 'Sarah Johnson',
                            specialization: 'Cleaning Specialist',
                            rating: 4.9,
                            experience: 3,
                            hourlyRate: 25,
                            imagePath: 'assets/images/worker1.jpg',
                          ),
                          _buildWorkerCard(
                            name: 'Michael Rodriguez',
                            specialization: 'Professional Chef',
                            rating: 4.7,
                            experience: 5,
                            hourlyRate: 40,
                            imagePath: 'assets/images/worker2.jpg',
                          ),
                          _buildWorkerCard(
                            name: 'Emma Wilson',
                            specialization: 'Childcare Provider',
                            rating: 4.8,
                            experience: 4,
                            hourlyRate: 30,
                            imagePath: 'assets/images/worker3.jpg',
                          ),
                          _buildWorkerCard(
                            name: 'David Chen',
                            specialization: 'Gardening Expert',
                            rating: 4.6,
                            experience: 7,
                            hourlyRate: 35,
                            imagePath: 'assets/images/worker4.jpg',
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

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          // TODO: Handle bottom navigation taps
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // Build service category card
  Widget _buildServiceCategory(String title, IconData icon) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
            child: Icon(icon, size: 28, color: Colors.teal),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Build worker card
  Widget _buildWorkerCard({
    required String name,
    required String specialization,
    required double rating,
    required int experience,
    required int hourlyRate,
    required String imagePath,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Worker Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              height: 70,
              width: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 35, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          // Worker Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 4),
                Text(specialization, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 3),
                    Text('$rating', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 10),
                    Icon(Icons.work, size: 16, color: Colors.teal[600]),
                    const SizedBox(width: 3),
                    Text('$experience yrs', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),

          // Rate and Book
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$$hourlyRate/hr', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[700])),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement booking logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Book'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
