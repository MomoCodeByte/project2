import 'package:flutter/material.dart';
import '../Clients/product_list.dart';
import '../Clients/Workers_Screen.dart';
import 'dart:math' as math;

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.75);
    
    var firstControlPoint = Offset(size.width * 0.25, size.height * 0.85);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    
    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.65);
    var secondEndPoint = Offset(size.width, size.height * 0.75);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class PlantIcon extends StatelessWidget {
  final double size;
  final Color color;

  const PlantIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    // Proper implementation of PlantIcon - returns a widget, not MaterialApp
    return Icon(
      Icons.local_florist,
      size: size,
      color: color,
    );
  }
}

class HouseholdServiceApp extends StatelessWidget {
  const HouseholdServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Household Service',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E3E5C),
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF4D5E80),
          ),
        ),
      ),
      // Define routes for navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/products': (context) => const ProductCategoriesScreen(),
        '/workers': (context) => const DomesticWorkersScreen(),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a key for the dropdown to access its state
    final GlobalKey<ServiceSelectionDropdownState> dropdownKey = GlobalKey<ServiceSelectionDropdownState>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo and App Name
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home_work_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Household Service",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3E5C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your one-stop solution for all household needs",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Illustration
                Expanded(
                  flex: 4,
                  child: Center(
                    child: Image.asset(
                      'assets/images/welcome_illustration.png', // Replace with your illustration asset
                      fit: BoxFit.contain,
                      // If you don't have an image yet, use placeholder
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.home_repair_service,
                              size: 100,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Service Selection
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "What are you looking for?",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ServiceSelectionDropdown(key: dropdownKey),
                    ],
                  ),
                ),
                // Get Started Button
                ElevatedButton(
                  onPressed: () {
                    // If a service is already selected in the dropdown, navigate there
                    if (dropdownKey.currentState?.selectedService != null) {
                      dropdownKey.currentState?.navigateToService(context);
                    } else {
                      // If no service is selected, show a message to select a service
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a service first'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceSelectionDropdown extends StatefulWidget {
  const ServiceSelectionDropdown({super.key});

  @override
  ServiceSelectionDropdownState createState() => ServiceSelectionDropdownState();
}

class ServiceSelectionDropdownState extends State<ServiceSelectionDropdown> {
  String? selectedService;
  final List<Map<String, dynamic>> services = [
    {
      'value': 'home_products',
      'label': 'Home/House Products',
      'icon': Icons.shopping_basket,
    },
    {
      'value': 'domestic_workers',
      'label': 'Domestic Workers',
      'icon': Icons.people,
    },
  ];

  void navigateToService(BuildContext context) {
    if (selectedService == null) return;
    
    // Navigate based on the selected option
    if (selectedService == 'home_products') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProductCategoriesScreen()),
      );
    } else if (selectedService == 'domestic_workers') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DomesticWorkersScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            isExpanded: true,
            value: selectedService,
            hint: const Text("Select a service"),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            iconSize: 24,
            elevation: 16,
            style: TextStyle(color: Colors.grey.shade800, fontSize: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onChanged: (String? newValue) {
              setState(() {
                selectedService = newValue;
              });
            },
            items: services.map<DropdownMenuItem<String>>((Map<String, dynamic> service) {
              return DropdownMenuItem<String>(
                value: service['value'],
                child: Row(
                  children: [
                    Icon(service['icon'], color: Colors.teal),
                    const SizedBox(width: 12),
                    Text(service['label']),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const HouseholdServiceApp());
}