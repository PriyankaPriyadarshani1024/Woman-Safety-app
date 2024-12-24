import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';

// Contact Model
class Contact {
  final String id;
  String name;
  String phone;

  Contact({required this.id, required this.name, required this.phone});

  factory Contact.fromMap(Map<String, dynamic> data, String id) {
    return Contact(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
    );
  }
}

// Contact Service
class ContactService {
  final Client client;
  late final Databases databases;

  ContactService({required this.client}) {
    databases = Databases(client);
  }

  // Add or Update contact
  Future<void> addOrUpdateContact({
    required String databaseId,
    required String collectionId,
    required String name,
    required String phone,
    required int selectedIndex,
    required List<Contact> contacts,
    required Function refreshContacts,
  }) async {
    try {
      if (selectedIndex == -1) {
        // Add new contact
        final response = await databases.createDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: 'unique()', // Auto-generated ID for each contact
          data: {'name': name, 'phone': phone},
          permissions: [
            Permission.read(Role.any()),
            Permission.write(Role.any()),
          ],
        );
        print('Contact added: ${response.data}');
      } else {
        // Update existing contact
        final response = await databases.updateDocument(
          databaseId: databaseId,
          collectionId: collectionId,
          documentId: contacts[selectedIndex].id,
          data: {'name': name, 'phone': phone},
        );
        print('Contact updated: ${response.data}');
      }
      refreshContacts(); // Refresh the contact list after saving
    } catch (e) {
      print('Error adding/updating contact: $e');
    }
  }

  // Fetch contacts from database
  Future<void> fetchContacts({
    required String databaseId,
    required String collectionId,
    required Function setContacts,
  }) async {
    try {
      final result = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
      );
      final contacts = result.documents
          .map((doc) => Contact.fromMap(doc.data, doc.$id))
          .toList();
      setContacts(contacts);
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }

  // Delete contact from database
  Future<void> deleteContact({
    required String databaseId,
    required String collectionId,
    required String contactId,
    required Function refreshContacts,
  }) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: contactId,
      );
      print('Contact deleted successfully');
      refreshContacts(); // Refresh the list after deletion
    } catch (e) {
      print('Error deleting contact: $e');
    }
  }
}

// Main Page
class MyTaskPage extends StatefulWidget {
  const MyTaskPage({Key? key}) : super(key: key);

  @override
  State<MyTaskPage> createState() => _MyTaskPageState();
}

class _MyTaskPageState extends State<MyTaskPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  List<Contact> contacts = [];
  int selectedIndex = -1;

  late ContactService contactService;

  @override
  void initState() {
    super.initState();
    Client client = Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('66eee5c400107d2ac9c7');

    contactService = ContactService(client: client);
    fetchContacts();
  }

  void fetchContacts() async {
    await contactService.fetchContacts(
      databaseId: '66eef6c00023912361eb',
      collectionId: '66f44198002e59611338',
      setContacts: (List<Contact> fetchedContacts) {
        setState(() {
          contacts = fetchedContacts;
        });
      },
    );
  }

  Widget getRow(int index) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: index % 2 == 0 ? Colors.deepPurpleAccent : Colors.purple,
          foregroundColor: Colors.white,
          child: Text(
            contacts[index].name[0],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contacts[index].name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(contacts[index].phone),
          ],
        ),
        trailing: SizedBox(
          width: 70,
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  nameController.text = contacts[index].name;
                  phoneController.text = contacts[index].phone;
                  setState(() {
                    selectedIndex = index;
                  });
                },
                child: const Icon(Icons.edit),
              ),
              InkWell(
                onTap: () {
                  contactService.deleteContact(
                    databaseId: '66eef6c00023912361eb',
                    collectionId: '66f44198002e59611338',
                    contactId: contacts[index].id,
                    refreshContacts: fetchContacts,
                  );
                },
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Contacts List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  hintText: 'Contact Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: const InputDecoration(
                  hintText: 'Phone Number',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ))),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    String name = nameController.text.trim();
                    String phone = phoneController.text.trim();
                    if (name.isNotEmpty && phone.isNotEmpty) {
                      setState(() {
                        nameController.clear();
                        phoneController.clear();
                      });
                      contactService.addOrUpdateContact(
                        databaseId: '66eef6c00023912361eb',
                        collectionId: '66f44198002e59611338',
                        name: name,
                        phone: phone,
                        selectedIndex: selectedIndex,
                        contacts: contacts,
                        refreshContacts: fetchContacts,
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String name = nameController.text.trim();
                    String phone = phoneController.text.trim();
                    if (name.isNotEmpty && phone.isNotEmpty && selectedIndex != -1) {
                      setState(() {
                        nameController.clear();
                        phoneController.clear();
                      });
                      contactService.addOrUpdateContact(
                        databaseId: '66eef6c00023912361eb',
                        collectionId: '66f44198002e59611338',
                        name: name,
                        phone: phone,
                        selectedIndex: selectedIndex,
                        contacts: contacts,
                        refreshContacts: fetchContacts,
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) => getRow(index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}