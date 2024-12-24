import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppwriteService {
  Client client = Client();
  late Account account;
  late Databases databases;


  Future<bool> checkLoginSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('sessionId');
    String? userId = prefs.getString('userId');

    // If both sessionId and userId exist, consider the user logged in
    return sessionId != null && userId != null;
  }

  Future<void> saveLoginSession(String userId, String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('token', token);
  }


  final String endpoint = "https://cloud.appwrite.io/v1"; // Appwrite endpoint
  final String projectId = "66eee5c400107d2ac9c7"; // Project ID
  final String databaseId = "66eef6c00023912361eb"; // Database ID
  final String usernameCollectionId = "66eef714003139a4b331"; // Username collection ID
  final String guardianscollectionId = "66f44198002e59611338";


  AppwriteService() {
    // Initialize Appwrite client
    client
        .setEndpoint(endpoint) // Appwrite Endpoint
        .setProject(projectId); // Project ID

    account = Account(client); // This is where Account is initialized correctly
    databases = Databases(client); // Initialize Databases


  }
  Future<Document> createContact(String contactId,String name, String contact) async {
    final response = await databases.createDocument(
      collectionId: guardianscollectionId,
      data: {'name': name, 'contact': contact},
      permissions: ['role:all'], databaseId: databaseId, documentId: contactId,
    );
    return response;
  }

  Future<List<Document>> getContacts() async {
    final response = await databases.listDocuments(
      collectionId: guardianscollectionId, databaseId: databaseId,
    );
    return response.documents;
  }

  Future<void> updateContact(String contactId, String name, String contact) async {
    await databases.updateDocument(
      collectionId: guardianscollectionId,
      documentId: contactId,
      data: {'name': name, 'contact': contact}, databaseId: databaseId,
    );
  }

  Future<void> deleteContact(String contactId) async {
    await databases.deleteDocument(
      collectionId: guardianscollectionId,
      documentId: contactId, databaseId: databaseId,
    );
  }
  // Create user
  Future<User> createUser(String email, String password, String name) async {
    try {
      final newUser = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      return newUser;
    } catch (error) {
      throw Exception("Failed to create user: $error");
    }
  }

  // Sign in
  Future<Session> signIn(String email, String password) async {
    try {
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return session;
    } catch (error) {
      throw Exception("Failed to sign in: $error");
    }
  }
  Future<void> signOut() async {
    try {
      await account.deleteSessions();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // Get current account details
  Future<User> getAccount() async {
    try {
      final accountDetails = await account.get();
      return accountDetails;
    } catch (error) {
      throw Exception("Failed to get account: $error");
    }
  }

  // Create user document in the database
  Future<Document> createUserDocument(String userId, String email, String name) async {
    try {
      final document = await databases.createDocument(
        databaseId: databaseId,
        collectionId: usernameCollectionId,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'email': email,
          'name': name,
        },
      );
      return document;
    } catch (error) {
      throw Exception("Failed to create user document: $error");
    }
  }
}
