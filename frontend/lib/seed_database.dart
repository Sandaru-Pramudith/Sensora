import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Utility class to seed Firebase Firestore with sample admin and staff data
class DatabaseSeeder {
  static bool get _hasFirebaseApp => Firebase.apps.isNotEmpty;

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Sample first names
  static const List<String> _firstNames = [
    'James',
    'Mary',
    'John',
    'Patricia',
    'Robert',
    'Jennifer',
    'Michael',
    'Linda',
    'William',
    'Elizabeth',
    'David',
    'Barbara',
    'Richard',
    'Susan',
    'Joseph',
    'Jessica',
    'Thomas',
    'Sarah',
    'Charles',
    'Karen',
    'Christopher',
    'Lisa',
    'Daniel',
    'Nancy',
    'Matthew',
    'Betty',
    'Anthony',
    'Margaret',
    'Mark',
    'Sandra',
    'Donald',
    'Ashley',
    'Steven',
    'Kimberly',
    'Paul',
    'Emily',
    'Andrew',
    'Donna',
    'Joshua',
    'Michelle',
    'Kenneth',
    'Dorothy',
    'Kevin',
    'Carol',
    'Brian',
    'Amanda',
    'George',
    'Melissa',
    'Timothy',
    'Deborah',
    'Ronald',
    'Stephanie',
    'Edward',
    'Rebecca',
    'Jason',
    'Sharon',
    'Jeffrey',
    'Laura',
    'Ryan',
    'Cynthia',
    'Jacob',
    'Kathleen',
    'Gary',
    'Amy',
    'Nicholas',
    'Angela',
    'Eric',
    'Shirley',
    'Jonathan',
    'Anna',
    'Stephen',
    'Brenda',
    'Larry',
    'Pamela',
    'Justin',
    'Emma',
    'Scott',
    'Nicole',
    'Brandon',
    'Helen',
    'Benjamin',
    'Samantha',
    'Samuel',
    'Katherine',
    'Raymond',
    'Christine',
    'Gregory',
    'Debra',
    'Frank',
    'Rachel',
    'Alexander',
    'Carolyn',
    'Patrick',
    'Janet',
    'Jack',
    'Catherine',
  ];

  // Sample last names
  static const List<String> _lastNames = [
    'Smith',
    'Johnson',
    'Williams',
    'Brown',
    'Jones',
    'Garcia',
    'Miller',
    'Davis',
    'Rodriguez',
    'Martinez',
    'Hernandez',
    'Lopez',
    'Gonzalez',
    'Wilson',
    'Anderson',
    'Thomas',
    'Taylor',
    'Moore',
    'Jackson',
    'Martin',
    'Lee',
    'Perez',
    'Thompson',
    'White',
    'Harris',
    'Sanchez',
    'Clark',
    'Ramirez',
    'Lewis',
    'Robinson',
    'Walker',
    'Young',
    'Allen',
    'King',
    'Wright',
    'Scott',
    'Torres',
    'Nguyen',
    'Hill',
    'Flores',
    'Green',
    'Adams',
    'Nelson',
    'Baker',
    'Hall',
    'Rivera',
    'Campbell',
    'Mitchell',
    'Carter',
    'Roberts',
    'Gomez',
    'Phillips',
    'Evans',
    'Turner',
    'Diaz',
    'Parker',
    'Cruz',
    'Edwards',
    'Collins',
    'Reyes',
    'Stewart',
    'Morris',
    'Morales',
    'Murphy',
    'Cook',
    'Rogers',
    'Gutierrez',
  ];

  // Admin positions
  static const List<String> _adminPositions = [
    'System Administrator',
    'Database Administrator',
    'Network Administrator',
    'Security Administrator',
    'IT Manager',
    'Operations Manager',
    'Technical Director',
    'Chief Technology Officer',
    'Infrastructure Lead',
    'DevOps Manager',
  ];

  // Staff positions
  static const List<String> _staffPositions = [
    'Warehouse Manager',
    'Quality Analyst',
    'Inventory Specialist',
    'Logistics Coordinator',
    'Shift Supervisor',
    'Production Worker',
    'Quality Control Inspector',
    'Forklift Operator',
    'Packaging Specialist',
    'Shipping Coordinator',
    'Receiving Clerk',
    'Stock Controller',
    'Supply Chain Analyst',
    'Maintenance Technician',
    'Safety Officer',
    'Production Planner',
    'Materials Handler',
    'Assembly Line Worker',
    'Warehouse Associate',
    'Distribution Specialist',
  ];

  /// Seeds the database with sample data
  /// Creates 20 admins and 80 staff members = 100 total
  static Future<void> seedDatabase() async {
    if (!_hasFirebaseApp) {
      debugPrint(
        'Skipping database seeding because Firebase is not initialized.',
      );
      return;
    }

    debugPrint('Starting database seeding...');

    // Use batch writes for much faster performance
    WriteBatch batch = _firestore.batch();

    // Create 20 admins
    debugPrint('Preparing admins...');
    for (int i = 0; i < 20; i++) {
      final docRef = _firestore.collection('admins').doc();
      batch.set(docRef, _getAdminData(i));
    }

    // Create 80 staff
    debugPrint('Preparing staff...');
    for (int i = 0; i < 80; i++) {
      final docRef = _firestore.collection('staff').doc();
      batch.set(docRef, _getStaffData(i));
    }

    // Commit all at once
    debugPrint('Writing to database...');
    await batch.commit();

    debugPrint('Database seeding completed! Total: 100 users');
  }

  static Map<String, dynamic> _getAdminData(int index) {
    final firstName = _firstNames[index % _firstNames.length];
    final lastName = _lastNames[index % _lastNames.length];
    final fullName = '$firstName $lastName';
    final email =
        '${firstName.toLowerCase()}.${lastName.toLowerCase()}@sensora.com';
    final position = _adminPositions[index % _adminPositions.length];
    final contact = '+1 ${_generatePhoneNumber(index)}';
    final username =
        '${firstName.toLowerCase()}${lastName.toLowerCase()}${index + 1}';

    return {
      'fullName': fullName,
      'email': email,
      'position': position,
      'contactNo': contact,
      'username': username,
      'password': 'Sensora@2024',
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    };
  }

  static Map<String, dynamic> _getStaffData(int index) {
    final firstName = _firstNames[(index + 20) % _firstNames.length];
    final lastName = _lastNames[(index + 20) % _lastNames.length];
    final fullName = '$firstName $lastName';
    final email =
        '${firstName.toLowerCase()}.${lastName.toLowerCase()}@sensora.com';
    final position = _staffPositions[index % _staffPositions.length];
    final contact = '+1 ${_generatePhoneNumber(index + 100)}';
    final username =
        '${firstName.toLowerCase()}${lastName.toLowerCase()}${index + 21}';

    return {
      'fullName': fullName,
      'email': email,
      'position': position,
      'contactNo': contact,
      'username': username,
      'password': 'Sensora@2024',
      'role': 'staff',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    };
  }

  static String _generatePhoneNumber(int seed) {
    final area = 200 + (seed % 800);
    final prefix = 100 + (seed * 7 % 900);
    final line = 1000 + (seed * 13 % 9000);
    return '$area-$prefix-$line';
  }

  /// Check if database has been seeded
  static Future<bool> isDatabaseSeeded() async {
    if (!_hasFirebaseApp) {
      return true;
    }
    final admins = await _firestore.collection('admins').limit(1).get();
    final staff = await _firestore.collection('staff').limit(1).get();
    return admins.docs.isNotEmpty && staff.docs.isNotEmpty;
  }

  /// Get all admins
  static Future<List<Map<String, dynamic>>> getAdmins() async {
    if (!_hasFirebaseApp) {
      return [];
    }
    final snapshot = await _firestore.collection('admins').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Get all staff
  static Future<List<Map<String, dynamic>>> getStaff() async {
    if (!_hasFirebaseApp) {
      return [];
    }
    final snapshot = await _firestore.collection('staff').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Get staff by ID
  static Future<Map<String, dynamic>?> getStaffById(String id) async {
    if (!_hasFirebaseApp) {
      return null;
    }
    final doc = await _firestore.collection('staff').doc(id).get();
    if (doc.exists) {
      return {'id': doc.id, ...doc.data()!};
    }
    return null;
  }

  /// Get admin by ID
  static Future<Map<String, dynamic>?> getAdminById(String id) async {
    if (!_hasFirebaseApp) {
      return null;
    }
    final doc = await _firestore.collection('admins').doc(id).get();
    if (doc.exists) {
      return {'id': doc.id, ...doc.data()!};
    }
    return null;
  }

  /// Update staff member
  static Future<void> updateStaff(String id, Map<String, dynamic> data) async {
    if (!_hasFirebaseApp) {
      return;
    }
    await _firestore.collection('staff').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update admin
  static Future<void> updateAdmin(String id, Map<String, dynamic> data) async {
    if (!_hasFirebaseApp) {
      return;
    }
    await _firestore.collection('admins').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete staff member
  static Future<void> deleteStaff(String id) async {
    if (!_hasFirebaseApp) {
      return;
    }
    await _firestore.collection('staff').doc(id).delete();
  }

  /// Delete admin
  static Future<void> deleteAdmin(String id) async {
    if (!_hasFirebaseApp) {
      return;
    }
    await _firestore.collection('admins').doc(id).delete();
  }

  /// Add new staff member
  static Future<String> addStaff(Map<String, dynamic> data) async {
    if (!_hasFirebaseApp) {
      return '';
    }
    final docRef = await _firestore.collection('staff').add({
      ...data,
      'role': 'staff',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    return docRef.id;
  }

  /// Add new admin
  static Future<String> addAdmin(Map<String, dynamic> data) async {
    if (!_hasFirebaseApp) {
      return '';
    }
    final docRef = await _firestore.collection('admins').add({
      ...data,
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    return docRef.id;
  }
}
