import 'package:flutter/material.dart';


class CaloriesPage extends StatefulWidget {
  const CaloriesPage({Key? key}) : super(key: key);

  @override
  State<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends State<CaloriesPage> {
  final List<Map<String, dynamic>> allFoods = [
    {"name": "Apple", "calories": 95},
    {"name": "Banana", "calories": 105},
    {"name": "Chicken Breast (100g)", "calories": 165},
    {"name": "Rice (1 cup)", "calories": 206},
    {"name": "Egg (1 large)", "calories": 78},
    {"name": "Protein Shake", "calories": 120},
    {"name": "Avocado (1)", "calories": 240},
  ];
  List<Map<String, dynamic>> loggedFoods = [];
  int totalCalories = 0;

  String query = "";

  @override
  Widget build(BuildContext context) {
    final filteredFoods = allFoods
        .where((food) =>
        food["name"].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calorie Tracker"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search food...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),

          // Total calories row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Calories Today:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("$totalCalories kcal",
                        style: const TextStyle(color: Colors.green, fontSize: 16)),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Reset"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      loggedFoods.clear();
                      totalCalories = 0;
                    });
                  },
                )
              ],
            ),
          ),

          // Logged food list (if any)
          if (loggedFoods.isNotEmpty)
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Logged Foods:",
                          style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: loggedFoods.length,
                      itemBuilder: (context, index) {
                        final food = loggedFoods[index];
                        return ListTile(
                          leading: const Icon(Icons.check_circle_outline,
                              color: Colors.green),
                          title: Text(food["name"]),
                          trailing: Text("${food["calories"]} kcal"),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Available food list with search (below logged list)
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: filteredFoods.length,
              itemBuilder: (context, index) {
                final food = filteredFoods[index];
                return ListTile(
                  leading: const Icon(Icons.fastfood),
                  title: Text(food["name"]),
                  subtitle: Text("${food["calories"]} kcal"),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        loggedFoods.add(food);
                        totalCalories += (food["calories"] as num).round();
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
