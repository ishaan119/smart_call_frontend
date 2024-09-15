import 'package:flutter/material.dart';
import 'api_service.dart';
import 'drawer_menu.dart';
import 'phone_verification_screen.dart';

class VerifiedNumbersScreen extends StatefulWidget {
  const VerifiedNumbersScreen({super.key});

  @override
  _VerifiedNumbersScreenState createState() => _VerifiedNumbersScreenState();
}

class _VerifiedNumbersScreenState extends State<VerifiedNumbersScreen> {
  final ApiService apiService = ApiService();
  List<VerifiedNumber> verifiedNumbers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVerifiedNumbers();
  }

  void fetchVerifiedNumbers() async {
    try {
      final numbers = await apiService.getVerifiedNumbers();
      setState(() {
        verifiedNumbers = numbers;
        isLoading = false;
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
      fetchVerifiedNumbers();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting phone number: $e')));
    }
  }

  void showDeleteConfirmationDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Phone Number"),
          content:
              const Text("Are you sure you want to delete this phone number?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                deleteNumber(id);
              },
            ),
          ],
        );
      },
    );
  }

  void showEditNameDialog(int id, String? currentName) {
    TextEditingController nameController =
        TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Name"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Name",
              hintText: "Enter a name",
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                "Save",
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                updateNumberName(id, nameController.text.trim());
              },
            ),
          ],
        );
      },
    );
  }

  void updateNumberName(int id, String name) async {
    try {
      await apiService.updateVerifiedNumber(id, name);
      fetchVerifiedNumbers();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating name: $e')));
    }
  }

  Widget buildNumberCard(VerifiedNumber number) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal[600],
          child: const Icon(Icons.phone, color: Colors.white),
        ),
        title: Text(
          number.name ?? number.phoneNumber,
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
        ),
        subtitle: number.name != null
            ? Text(
                number.phoneNumber,
                style: const TextStyle(fontSize: 16.0, color: Colors.grey),
              )
            : null,
        trailing: Wrap(
          spacing: 12, // space between two icons
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                showEditNameDialog(number.id, number.name);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () {
                showDeleteConfirmationDialog(number.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verified Numbers'),
        centerTitle: true,
      ),
      drawer: const DrawerMenu(),
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : verifiedNumbers.isEmpty
                ? const Center(
                    child: Text(
                    'No verified numbers found',
                    style: TextStyle(fontSize: 18.0),
                  ))
                : ListView.builder(
                    itemCount: verifiedNumbers.length,
                    itemBuilder: (context, index) {
                      final number = verifiedNumbers[index];
                      return buildNumberCard(number);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const PhoneVerificationScreen()),
          ).then((_) => fetchVerifiedNumbers());
        },
        backgroundColor: Colors.teal[600],
        child: const Icon(Icons.add),
      ),
    );
  }
}
