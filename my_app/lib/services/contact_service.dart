import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_app/models/contact_model.dart';

class ContactService {
  // Fields
  final FirebaseFirestore _firestore;

  // Constructor
  ContactService({FirebaseFirestore? firestore}) 
  : _firestore = firestore ?? FirebaseFirestore.instance;

  //methods
  CollectionReference<Map<String, dynamic>> get _contacts{
    return _firestore.collection('contacts');
  }

  // create a new contact

  Future<void> addContact(ContactModel contact) async {
    await _contacts.add({
      ...contact.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
// delete a contact
  Future<void> deleteContact(String id) async {
    await _contacts.doc(id).delete();
  }

  // get all contacts
  Stream<List<ContactModel>> getContacts() {
    return _contacts.snapshots().map(
      (contact) => contact.docs.map(ContactModel.fromFirestore).toList(),
    );
  }

  // update a contact
  Future<void> updateContact(String id, ContactModel contact) async {
    await _contacts.doc(id).update({
      ...contact.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
