import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Worker {
  final int id;
  final String name;
  final String description;
  final double price;
  final int availability;
  final String specialist;
  final int age;
  final String location;
  final String phone;
  final String workHour;
  double rating; // Not in DB but shown in UI
  int experience; // Not in DB but can be calculated or added

  Worker({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.availability,
    required this.specialist,
    required this.age,
    required this.location,
    required this.phone,
    required this.workHour,
    this.rating = 0.0,
    this.experience = 0,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['worker_id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      availability: json['availability'] ?? 0,
      specialist: json['specialist'] ?? '',
      age: json['age'] ?? 0,
      location: json['location'] ?? '',
      phone: json['phone'] ?? '',
      workHour: json['work_hour'] ?? '',
      rating:
          json['rating'] != null
              ? double.parse(json['rating'].toString())
              : 0.0,
      experience: json['experience'] ?? 0,
    );
  }
}

class WorkerDetailScreen extends StatefulWidget {
  final int? workerId;

  const WorkerDetailScreen({Key? key, this.workerId}) : super(key: key);

  @override
  _WorkerDetailScreenState createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  List<Worker> workers = [];
  List<Worker> filteredWorkers = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedSpecialty = 'All';
  List<String> specialties = [
    'All',
    'Cleaning',
    'Cooking',
    'Childcare',
    'Gardening',
    'Plumbing',
    'Electrical',
  ];
  String sortBy = 'Top Rated';
  List<String> sortOptions = [
    'Top Rated',
    'Price: Low to High',
    'Price: High to Low',
    'Experience',
  ];

  @override
  void initState() {
    super.initState();
    fetchWorkers();
  }

  Future<void> fetchWorkers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/workers'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          workers =
              data.map((worker) {
                // Add mock rating and experience for UI purposes
                final workerData = {...(worker as Map<String, dynamic>)};
                workerData['rating'] =
                    (3.5 +
                        (worker['worker_id'] % 3) *
                            0.5); // Random rating between 3.5-5.0
                workerData['experience'] =
                    1 +
                    (worker['worker_id'] %
                        10); // Random experience between 1-10 years
                return Worker.fromJson(workerData);
              }).toList();

          // Initial filtering
          applyFilters();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load workers');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorSnackBar('Error fetching workers: $e');
    }
  }

  void applyFilters() {
    setState(() {
      filteredWorkers =
          workers.where((worker) {
            // Apply search filter
            final nameMatch = worker.name.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
            final descriptionMatch = worker.description.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );
            final locationMatch = worker.location.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );

            // Apply specialty filter
            final specialtyMatch =
                selectedSpecialty == 'All' ||
                worker.specialist.toLowerCase() ==
                    selectedSpecialty.toLowerCase();

            return (nameMatch || descriptionMatch || locationMatch) &&
                specialtyMatch;
          }).toList();

      // Apply sorting
      switch (sortBy) {
        case 'Top Rated':
          filteredWorkers.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'Price: Low to High':
          filteredWorkers.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'Price: High to Low':
          filteredWorkers.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'Experience':
          filteredWorkers.sort((a, b) => b.experience.compareTo(a.experience));
          break;
      }
    });
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFF009688),
        elevation: 0,
        title: Text(
          'Domestic Workers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(16),
            color: Color(0xFF009688),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Find Skilled Professionals',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'for Your Home',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                // Search Box
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search for services...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    suffixIcon: Icon(Icons.filter_list, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),

          // Specialties Section
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    'Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        specialties.length -
                        1, // Skip "All" in the visual display
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final specialty =
                          specialties[index +
                              1]; // Skip "All" in the visual display
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSpecialty = specialty;
                            applyFilters();
                          });
                        },
                        child: Container(
                          width: 80,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      selectedSpecialty == specialty
                                          ? Color(0xFF009688)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Color(0xFF009688),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _getIconForSpecialty(specialty),
                                  color:
                                      selectedSpecialty == specialty
                                          ? Colors.white
                                          : Color(0xFF009688),
                                  size: 24,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                specialty,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      selectedSpecialty == specialty
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Available Workers Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Workers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: sortBy,
                  underline: SizedBox(),
                  icon: Icon(Icons.keyboard_arrow_down),
                  items:
                      sortOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        sortBy = newValue;
                        applyFilters();
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Workers List
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF009688),
                      ),
                    )
                    : filteredWorkers.isEmpty
                    ? Center(
                      child: Text('No workers found matching your criteria'),
                    )
                    : ListView.builder(
                      itemCount: filteredWorkers.length,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final worker = filteredWorkers[index];
                        return _buildWorkerCard(worker);
                      },
                    ),
          ),

          // Bottom Navigation
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home, 'Home', true),
                _buildNavItem(Icons.search, 'Search', false),
                _buildNavItem(Icons.calendar_today, 'Bookings', false),
                _buildNavItem(Icons.person, 'Profile', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(Worker worker) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerProfileScreen(worker: worker),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
              ),
              SizedBox(width: 16),
              // Worker Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      worker.specialist,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        SizedBox(width: 4),
                        Text(
                          worker.rating.toStringAsFixed(1),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.access_time, color: Colors.grey, size: 18),
                        SizedBox(width: 4),
                        Text('${worker.experience} yrs'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      worker.description.isNotEmpty
                          ? worker.description
                          : 'Professional ${worker.specialist} with ${worker.experience} years of experience.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Price and Book Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${worker.price.toStringAsFixed(0)}/hr',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Handle booking
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF009688),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text('BOOK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? Color(0xFF009688) : Colors.grey, size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Color(0xFF009688) : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  IconData _getIconForSpecialty(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'cleaning':
        return Icons.cleaning_services;
      case 'cooking':
        return Icons.restaurant;
      case 'childcare':
        return Icons.child_care;
      case 'gardening':
        return Icons.yard;
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      default:
        return Icons.work;
    }
  }
}

// Worker Profile Screen for detailed view
class WorkerProfileScreen extends StatelessWidget {
  final Worker worker;

  const WorkerProfileScreen({Key? key, required this.worker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF009688),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                worker.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                color: Color(0xFF009688),
                child: Center(
                  child: Icon(
                    _getIconForSpecialty(worker.specialist),
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.specialist,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  '${worker.rating.toStringAsFixed(1)} (${20 + worker.id * 3} reviews)',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${worker.experience} years experience',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Price and Availability
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Hourly Rate',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '\$${worker.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF009688),
                              ),
                            ),
                          ],
                        ),
                        VerticalDivider(
                          thickness: 1,
                          width: 40,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Text(
                              'Availability',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              worker.availability == 1
                                  ? 'Available'
                                  : 'Unavailable',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color:
                                    worker.availability == 1
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        VerticalDivider(
                          thickness: 1,
                          width: 40,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Text(
                              'Hours',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              worker.workHour.isNotEmpty
                                  ? worker.workHour
                                  : 'Flexible',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // About
                  Text(
                    'About',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    worker.description.isNotEmpty
                        ? worker.description
                        : 'Professional ${worker.specialist} with ${worker.experience} years of experience. Dedicated to providing high-quality service with attention to detail. Available for both short-term and long-term assignments.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  SizedBox(height: 24),

                  // Contact Information
                  Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildContactItem(
                    Icons.phone,
                    'Phone',
                    worker.phone.isNotEmpty
                        ? worker.phone
                        : '+1 (555) 123-4567',
                  ),
                  SizedBox(height: 12),
                  _buildContactItem(
                    Icons.location_on,
                    'Location',
                    worker.location.isNotEmpty
                        ? worker.location
                        : 'City Center',
                  ),
                  SizedBox(height: 12),
                  _buildContactItem(
                    Icons.calendar_today,
                    'Age',
                    '${worker.age} years old',
                  ),

                  SizedBox(height: 32),

                  // Book Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle booking
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Booking request sent for ${worker.name}',
                            ),
                            backgroundColor: Color(0xFF009688),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF009688),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'BOOK NOW',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xFF009688).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFF009688)),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getIconForSpecialty(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'cleaning':
        return Icons.cleaning_services;
      case 'cooking':
        return Icons.restaurant;
      case 'childcare':
        return Icons.child_care;
      case 'gardening':
        return Icons.yard;
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      default:
        return Icons.work;
    }
  }
}
