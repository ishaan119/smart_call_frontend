import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class PhoneNumberSelectionDialog extends StatelessWidget {
  final Contact contact;

  const PhoneNumberSelectionDialog({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Phone Number'),
      content: SizedBox(
        width: double.maxFinite,
        height: 200, // Adjust height as needed
        child: contact.phones.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: contact.phones.length,
                itemBuilder: (context, index) {
                  String phoneNumber = contact.phones[index].number;
                  return ListTile(
                    title: Text(phoneNumber),
                    onTap: () => Navigator.pop(context, phoneNumber),
                  );
                },
              )
            : const Center(
                child: Text('No phone numbers available for this contact.'),
              ),
      ),
    );
  }
}
