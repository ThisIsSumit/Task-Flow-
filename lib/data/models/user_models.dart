import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phoneNumber;
  String? photoUrl;
  DateTime createdAt;
  Map<String, int> taskStats;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.photoUrl,
    DateTime? createdAt,
    Map<String, int>? taskStats,
  }) : this.createdAt = createdAt ?? DateTime.now(),
       this.taskStats =
           taskStats ?? {'completed': 0, 'pending': 0, 'overdue': 0};

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'taskStats': taskStats,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      taskStats: Map<String, int>.from(
        map['taskStats'] ?? {'completed': 0, 'pending': 0, 'overdue': 0},
      ),
    );
  }
}
