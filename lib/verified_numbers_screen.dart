import 'package:flutter/material.dart';
import 'api_service.dart';
import 'drawer_menu.dart';
import 'phone_verification_screen.dart'; // Import the PhoneVerificationScreen

class VerifiedNumbersScreen extends StatefulWidget {
  const VerifiedNumbersScreen({super.key});

  @override
  _VerifiedNumbersScreenState createState() => _VerifiedNumbersScreenState();
}

class _VerifiedNumbersScreenState extends State<VerifiedNumbersScreen> {
  final ApiService apiService = ApiService(); // Initialize the ApiService
  List<Map<String, dynamic>> verifiedNumbers = [];
  bool isLoading = true; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    fetchVerifiedNumbers(); // Fetch verified numbers when the screen loads
  }

  void fetchVerifiedNumbers() async {
    try {
      final numbers = await apiService.getVerifiedNumbers();
      setState(() {
        verifiedNumbers = numbers.map((number) {
          return {
            'id': number['id'] as int,
            'phone_number': number['phone_number'] as String,
          };
        }).toList();
        isLoading = false; // Hide the loading indicator once data is fetched
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching verified numbers: $e')));
    }
  }

  void deleteNumber(int id) async {
    try {
      await apiService.deleteVerifiedNumber(id);
      fetchVerifiedNumbers(); // Refresh the list after deletion
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting phone number: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verified Numbers',
            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      drawer: const DrawerMenu(),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: verifiedNumbers.isEmpty
                    ? const Center(child: Text('No verified numbers found'))
                    : ListView.builder(
                        itemCount: verifiedNumbers.length,
                        itemBuilder: (context, index) {
                          final number = verifiedNumbers[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: ListTile(
                              leading:
                                  const Icon(Icons.phone, color: Colors.green),
                              title: Text(
                                number['phone_number'],
                                style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w600),
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  deleteNumber(number['id']);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PhoneVerificationScreen()),
          ).then((_) => fetchVerifiedNumbers()); // Refresh numbers after adding
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
