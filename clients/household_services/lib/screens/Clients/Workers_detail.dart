import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Worker {
  final int workerId;
  final int? adminId;
  final String name;
  final String description;
  final double price;
  final int availability;
  final String specialist;
  final int age;
  final String location;
  final String phone;
  final String workHour;
  double rating;
  int experience;

  Worker({
    required this.workerId,
    this.adminId,
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
      workerId: json['worker_id'],
      adminId: json['admin_id'],
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

  Map<String, dynamic> toJson() => {
    'worker_id': workerId,
    'admin_id': adminId,
    'name': name,
    'description': description,
    'price': price,
    'availability': availability,
    'specialist': specialist,
    'age': age,
    'location': location,
    'phone': phone,
    'work_hour': workHour,
    'rating': rating,
    'experience': experience,
  };
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

  // Filter variables
  String selectedSpecialty = 'All';
  String selectedLocation = 'All';
  RangeValues priceRange = RangeValues(0, 1000);
  RangeValues ageRange = RangeValues(18, 65);
  bool showFilters = false;

  List<String> specialties = ['All'];
  List<String> locations = ['All'];

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
      workers = [];
      filteredWorkers = [];
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/workers'),
        headers: {'Content-Type': 'application/json'},
      );

      print('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);

        if (responseData.isEmpty) {
          showErrorSnackBar('No workers found');
          return;
        }

        setState(() {
          workers =
              responseData.map((workerJson) {
                final workerData = workerJson as Map<String, dynamic>;
                workerData['rating'] ??=
                    (3.5 + (workerData['worker_id'] % 3) * 0.5);
                workerData['experience'] ??= 1 + (workerData['worker_id'] % 10);
                return Worker.fromJson(workerData);
              }).toList();

          _updateFilterOptions();
          applyFilters();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load workers: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorSnackBar('Error fetching workers: $e');
      print('Error details: $e');
    }
  }

  void _updateFilterOptions() {
    // Get all unique locations from workers
    final allLocations =
        workers
            .map((w) => w.location)
            .where((loc) => loc.isNotEmpty)
            .toSet()
            .toList();
    locations = ['All', ...allLocations];

    // Get all unique specialties from workers
    final allSpecialties =
        workers
            .map((w) => w.specialist)
            .where((spec) => spec.isNotEmpty)
            .toSet()
            .toList();
    specialties = ['All', ...allSpecialties];

    // Initialize price range
    if (workers.isNotEmpty) {
      final prices = workers.map((w) => w.price).toList();
      final minPrice = prices.reduce((min, price) => price < min ? price : min);
      final maxPrice = prices.reduce((max, price) => price > max ? price : max);
      priceRange = RangeValues(minPrice, maxPrice);
    }

    // Initialize age range
    if (workers.isNotEmpty) {
      final ages = workers.map((w) => w.age.toDouble()).toList();
      final minAge = ages.reduce((min, age) => age < min ? age : min);
      final maxAge = ages.reduce((max, age) => age > max ? age : max);
      ageRange = RangeValues(minAge, maxAge);
    }
  }

  void applyFilters() {
    setState(() {
      filteredWorkers =
          workers.where((worker) {
            // Search filter
            final searchMatch =
                searchQuery.isEmpty ||
                worker.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                worker.description.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                worker.location.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                );

            // Specialty filter
            final specialtyMatch =
                selectedSpecialty == 'All' ||
                worker.specialist == selectedSpecialty;

            // Location filter
            final locationMatch =
                selectedLocation == 'All' ||
                worker.location == selectedLocation;

            // Price filter
            final priceMatch =
                worker.price >= priceRange.start &&
                worker.price <= priceRange.end;

            // Age filter
            final ageMatch =
                worker.age >= ageRange.start && worker.age <= ageRange.end;

            return searchMatch &&
                specialtyMatch &&
                locationMatch &&
                priceMatch &&
                ageMatch;
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        elevation: 0,
        title: const Text(
          'Domestic Workers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              setState(() {
                showFilters = !showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchWorkers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF009688),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Find Skilled Professionals',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'for Your Home',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
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
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),

          // Filters Section
          if (showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedSpecialty = 'All';
                            selectedLocation = 'All';
                            if (workers.isNotEmpty) {
                              final prices =
                                  workers.map((w) => w.price).toList();
                              priceRange = RangeValues(
                                prices.reduce(
                                  (min, price) => price < min ? price : min,
                                ),
                                prices.reduce(
                                  (max, price) => price > max ? price : max,
                                ),
                              );
                              final ages =
                                  workers.map((w) => w.age.toDouble()).toList();
                              ageRange = RangeValues(
                                ages.reduce(
                                  (min, age) => age < min ? age : min,
                                ),
                                ages.reduce(
                                  (max, age) => age > max ? age : max,
                                ),
                              );
                            }
                            applyFilters();
                          });
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Specialty Filter
                  const Text(
                    'Specialty',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: selectedSpecialty,
                      isExpanded: true,
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedSpecialty = newValue;
                            applyFilters();
                          });
                        }
                      },
                      items:
                          specialties.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Filter
                  const Text(
                    'Location',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: selectedLocation,
                      isExpanded: true,
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedLocation = newValue;
                            applyFilters();
                          });
                        }
                      },
                      items:
                          locations.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price Range Filter
                  Text(
                    'Price Range (Tsh ${priceRange.start.toInt()} - Tsh ${priceRange.end.toInt()})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    values: priceRange,
                    min:
                        workers.isNotEmpty
                            ? workers
                                .map((w) => w.price)
                                .reduce(
                                  (min, price) => price < min ? price : min,
                                )
                            : 0,
                    max:
                        workers.isNotEmpty
                            ? workers
                                .map((w) => w.price)
                                .reduce(
                                  (max, price) => price > max ? price : max,
                                )
                            : 1000,
                    divisions: 20,
                    activeColor: const Color(0xFF009688),
                    inactiveColor: Colors.grey[300],
                    labels: RangeLabels(
                      'Tsh ${priceRange.start.toInt()}',
                      'Tsh ${priceRange.end.toInt()}',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        priceRange = values;
                      });
                    },
                    onChangeEnd: (RangeValues values) {
                      applyFilters();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Age Range Filter
                  Text(
                    'Age Range (${ageRange.start.toInt()} - ${ageRange.end.toInt()} years)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    values: ageRange,
                    min:
                        workers.isNotEmpty
                            ? workers
                                .map((w) => w.age.toDouble())
                                .reduce((min, age) => age < min ? age : min)
                            : 18,
                    max:
                        workers.isNotEmpty
                            ? workers
                                .map((w) => w.age.toDouble())
                                .reduce((max, age) => age > max ? age : max)
                            : 65,
                    divisions: 47,
                    activeColor: const Color(0xFF009688),
                    inactiveColor: Colors.grey[300],
                    labels: RangeLabels(
                      '${ageRange.start.toInt()}',
                      '${ageRange.end.toInt()}',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        ageRange = values;
                      });
                    },
                    onChangeEnd: (RangeValues values) {
                      applyFilters();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Apply Filters Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        applyFilters();
                        setState(() {
                          showFilters = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('APPLY FILTERS'),
                    ),
                  ),
                ],
              ),
            ),

          // Specialties Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 8),
                  child: Text(
                    'Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: specialties.length - 1, // Skip "All"
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final specialty = specialties[index + 1];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSpecialty = specialty;
                            applyFilters();
                          });
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      selectedSpecialty == specialty
                                          ? const Color(0xFF009688)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF009688),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _getIconForSpecialty(specialty),
                                  color:
                                      selectedSpecialty == specialty
                                          ? Colors.white
                                          : const Color(0xFF009688),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
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

          // Active Filters Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                if (selectedSpecialty != 'All')
                  _buildFilterChip('Service: $selectedSpecialty', () {
                    setState(() {
                      selectedSpecialty = 'All';
                      applyFilters();
                    });
                  }),
                if (selectedLocation != 'All')
                  _buildFilterChip('Location: $selectedLocation', () {
                    setState(() {
                      selectedLocation = 'All';
                      applyFilters();
                    });
                  }),
                if (priceRange.start >
                        (workers.isNotEmpty
                            ? workers
                                .map((w) => w.price)
                                .reduce(
                                  (min, price) => price < min ? price : min,
                                )
                            : 0) ||
                    priceRange.end <
                        (workers.isNotEmpty
                            ? workers
                                .map((w) => w.price)
                                .reduce(
                                  (max, price) => price > max ? price : max,
                                )
                            : 1000))
                  _buildFilterChip(
                    'Price: Tsh ${priceRange.start.toInt()}-Tsh ${priceRange.end.toInt()}',
                    () {
                      setState(() {
                        if (workers.isNotEmpty) {
                          final prices = workers.map((w) => w.price).toList();
                          priceRange = RangeValues(
                            prices.reduce(
                              (min, price) => price < min ? price : min,
                            ),
                            prices.reduce(
                              (max, price) => price > max ? price : max,
                            ),
                          );
                        }
                        applyFilters();
                      });
                    },
                  ),
                if (ageRange.start >
                        (workers.isNotEmpty
                            ? workers
                                .map((w) => w.age.toDouble())
                                .reduce((min, age) => age < min ? age : min)
                            : 18) ||
                    ageRange.end <
                        (workers.isNotEmpty
                            ? workers
                                .map((w) => w.age.toDouble())
                                .reduce((max, age) => age > max ? age : max)
                            : 65))
                  _buildFilterChip(
                    'Age: ${ageRange.start.toInt()}-${ageRange.end.toInt()}',
                    () {
                      setState(() {
                        if (workers.isNotEmpty) {
                          final ages =
                              workers.map((w) => w.age.toDouble()).toList();
                          ageRange = RangeValues(
                            ages.reduce((min, age) => age < min ? age : min),
                            ages.reduce((max, age) => age > max ? age : max),
                          );
                        }
                        applyFilters();
                      });
                    },
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
                  'Available Workers (${filteredWorkers.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<String>(
                  value: sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down),
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
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF009688),
                      ),
                    )
                    : filteredWorkers.isEmpty
                    ? const Center(
                      child: Text('No workers found matching your criteria'),
                    )
                    : RefreshIndicator(
                      color: const Color(0xFF009688),
                      onRefresh: fetchWorkers,
                      child: ListView.builder(
                        itemCount: filteredWorkers.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final worker = filteredWorkers[index];
                          return _buildWorkerCard(worker);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: const Color(0xFF009688),
      deleteIconColor: Colors.white,
      onDeleted: onRemove,
    );
  }

  Widget _buildWorkerCard(Worker worker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              // Worker Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worker.specialist,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          worker.location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          worker.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.access_time,
                          color: Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text('${worker.experience} yrs'),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text('${worker.age} yrs old'),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                    'Tsh ${worker.price.toStringAsFixed(0)}/hr',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Handle booking
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('BOOK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

class WorkerProfileScreen extends StatelessWidget {
  final Worker worker;

  const WorkerProfileScreen({Key? key, required this.worker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(worker.name),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                worker.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                worker.specialist,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 30),
            _buildProfileItem(
              Icons.star,
              'Rating',
              worker.rating.toStringAsFixed(1),
            ),
            _buildProfileItem(
              Icons.work,
              'Experience',
              '${worker.experience} years',
            ),
            _buildProfileItem(
              Icons.calendar_today,
              'Age',
              '${worker.age} years',
            ),
            _buildProfileItem(Icons.location_on, 'Location', worker.location),
            _buildProfileItem(Icons.phone, 'Phone', worker.phone),
            _buildProfileItem(
              Icons.access_time,
              'Working Hours',
              worker.workHour,
            ),
            _buildProfileItem(
              Icons.attach_money,
              'Hourly Rate',
              'Tsh ${worker.price.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 20),
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              worker.description.isNotEmpty
                  ? worker.description
                  : 'Professional ${worker.specialist} with ${worker.experience} years of experience.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle booking
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('BOOK NOW', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF009688)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
