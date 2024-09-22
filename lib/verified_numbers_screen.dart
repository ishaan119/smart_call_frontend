// verified_numbers_screen.dart

import 'package:flutter/material.dart';
import 'api_service.dart';
import 'drawer_menu.dart';
import 'phone_verification_screen.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'models/verified_number.dart';

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
      showCustomSnackBar('Error fetching verified numbers: $e',
          color: Colors.red);
    }
  }

  void deleteNumber(int id) async {
    try {
      await apiService.deleteVerifiedNumber(id);
      fetchVerifiedNumbers();
      showCustomSnackBar('Phone number deleted successfully',
          color: Colors.green);
    } catch (e) {
      showCustomSnackBar('Error deleting phone number: $e', color: Colors.red);
    }
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
      showCustomSnackBar('Name updated successfully', color: Colors.green);
    } catch (e) {
      showCustomSnackBar('Error updating name: $e', color: Colors.red);
    }
  }

  Widget buildNumberCard(VerifiedNumber number) {
    return Slidable(
      key: ValueKey(number.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => showEditNameDialog(number.id, number.name),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        dismissible: DismissiblePane(onDismissed: () {
          deleteNumber(number.id);
        }),
        children: [
          SlidableAction(
            onPressed: (context) => deleteNumber(number.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.teal[600],
            child: Text(
              number.name != null && number.name!.isNotEmpty
                  ? number.name![0].toUpperCase()
                  : '#',
              style: const TextStyle(color: Colors.white),
            ),
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
        ),
      ),
    );
  }

  void showCustomSnackBar(String message, {Color? color}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: color ?? Colors.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.contact_phone,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No verified numbers found',
                          style: TextStyle(fontSize: 18.0),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Verify Phone Number'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PhoneVerificationScreen(),
                              ),
                            ).then((_) => fetchVerifiedNumbers());
                          },
                        ),
                      ],
                    ),
                  )
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
              builder: (context) => const PhoneVerificationScreen(),
            ),
          ).then((_) => fetchVerifiedNumbers());
        },
        backgroundColor: Colors.teal[600],
        child: const Icon(Icons.add),
      ),
    );
  }
}
