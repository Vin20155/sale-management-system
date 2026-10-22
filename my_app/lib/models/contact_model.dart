import 'package:cloud_firestore/cloud_firestore.dart';

class ContactModel {
  // fields
  final String id;
  final String firstName;
  final String lastName;
  final String gender;
  final String phone;
  final String? company;
  final DateTime? createdAt;
  // constructor (paramaterized constructor)
  ContactModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.phone,
    this.company,
    this.createdAt,
  });
  // methods
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'gender': gender,
      'phone': phone.trim(),
      'company': company,
    };
  }
  factory ContactModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return ContactModel(
      id: document.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      gender: data['gender'] ?? '',
      phone: data['phone'] ?? '',
      company: data['company'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}