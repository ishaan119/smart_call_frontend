import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactSelectionDialog extends StatefulWidget {
  final List<Contact> contacts;

  const ContactSelectionDialog({Key? key, required this.contacts})
      : super(key: key);

  @override
  _ContactSelectionDialogState createState() => _ContactSelectionDialogState();
}

class _ContactSelectionDialogState extends State<ContactSelectionDialog> {
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
    _searchController.addListener(_filterContacts);
    _focusNode.requestFocus();
  }

  void _filterContacts() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = widget.contacts.where((contact) {
        return contact.displayName.toLowerCase().contains(searchTerm);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Contact'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: 'Search contacts',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredContacts.isNotEmpty
                  ? ListView.builder(
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        Contact contact = _filteredContacts[index];
                        return ListTile(
                          title: Text(contact.displayName),
                          onTap: () => Navigator.pop(context, contact),
                        );
                      },
                    )
                  : const Center(
                      child: Text('No contacts found.'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
