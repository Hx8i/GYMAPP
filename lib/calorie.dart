import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';

class CaloriesPage extends StatefulWidget {
  const CaloriesPage({Key? key}) : super(key: key);

  @override
  State<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends State<CaloriesPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _gramsController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, dynamic>> loggedFoods = [];
  bool isLoading = false;
  String errorMessage = '';
  bool isScanning = false;

  // Nutritionix API credentials
  final String appId = 'e43bfa08'; // Replace with your Nutritionix App ID
  final String appKey = '1d81898bcefe7695ed3b765026cdb4ef'; // Replace with your Nutritionix App Key

  // Daily totals
  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;

  Future<void> searchFood(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('https://trackapi.nutritionix.com/v2/natural/nutrients'),
        headers: {
          'x-app-id': appId,
          'x-app-key': appKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': query,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          searchResults = List<Map<String, dynamic>>.from(data['foods']);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch food data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> searchByBarcode(String barcode) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://trackapi.nutritionix.com/v2/search/item?upc=$barcode'),
        headers: {
          'x-app-id': appId,
          'x-app-key': appKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['foods'] != null && data['foods'].isNotEmpty) {
          setState(() {
            searchResults = List<Map<String, dynamic>>.from(data['foods']);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'No food found for this barcode';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to fetch food data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void addFood(Map<String, dynamic> food, double grams) {
    final double servingWeight = food['serving_weight_grams'].toDouble();
    final double ratio = grams / servingWeight;

    final Map<String, dynamic> loggedFood = {
      'name': food['food_name'],
      'calories': (food['nf_calories'] * ratio).round(),
      'protein': (food['nf_protein'] * ratio).roundToDouble(),
      'carbs': (food['nf_total_carbohydrate'] * ratio).roundToDouble(),
      'fat': (food['nf_total_fat'] * ratio).roundToDouble(),
      'grams': grams,
    };

    setState(() {
      loggedFoods.add(loggedFood);
      totalCalories += loggedFood['calories'];
      totalProtein += loggedFood['protein'];
      totalCarbs += loggedFood['carbs'];
      totalFat += loggedFood['fat'];
    });
  }

  void removeFood(int index) {
    setState(() {
      totalCalories -= loggedFoods[index]['calories'];
      totalProtein -= loggedFoods[index]['protein'];
      totalCarbs -= loggedFoods[index]['carbs'];
      totalFat -= loggedFoods[index]['fat'];
      loggedFoods.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Calorie Tracker"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.close : Icons.qr_code_scanner),
            onPressed: () {
              setState(() {
                isScanning = !isScanning;
                if (!isScanning) {
                  searchResults = [];
                }
              });
            },
          ),
        ],
      ),
      body: isScanning
          ? _buildScanner()
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search food...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchResults = [];
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSubmitted: searchFood,
                  ),
                ),

                // Daily Summary
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    children: [
                      const Text(
                        "Daily Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMacroCard("Calories", "${totalCalories.round()}", "kcal"),
                          _buildMacroCard("Protein", "${totalProtein.round()}", "g"),
                          _buildMacroCard("Carbs", "${totalCarbs.round()}", "g"),
                          _buildMacroCard("Fat", "${totalFat.round()}", "g"),
                        ],
                      ),
                    ],
                  ),
                ),

                // Logged Foods
                if (loggedFoods.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Logged Foods",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: loggedFoods.length,
                            itemBuilder: (context, index) {
                              final food = loggedFoods[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            food['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${food['grams']}g • ${food['calories']} kcal",
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => removeFood(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Search Results
                if (searchResults.isNotEmpty)
                  Expanded(
                    flex: 2,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final food = searchResults[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food['food_name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${food['serving_weight_grams']}g • ${food['nf_calories'].round()} kcal",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: TextField(
                                          controller: _gramsController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            hintText: "Grams",
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () {
                                          if (_gramsController.text.isNotEmpty) {
                                            addFood(
                                              food,
                                              double.parse(_gramsController.text),
                                            );
                                            _gramsController.clear();
                                            setState(() {
                                              searchResults = [];
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),

                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  searchByBarcode(barcode.rawValue!);
                  setState(() {
                    isScanning = false;
                  });
                  break;
                }
              }
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black,
          child: const Text(
            "Scan a food barcode",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroCard(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "$label ($unit)",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
