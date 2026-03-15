import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionType { free, premium }

class UserModel {
  final String uid;
  final String userId;
  final String email;
  final String name;
  final String? phoneNumber;
  String? photoUrl;
  DateTime createdAt;
  Map<String, int> taskStats;
  final SubscriptionType subscriptionType;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;

  UserModel({
    required this.uid,
    String? userId,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.photoUrl,
    DateTime? createdAt,
    Map<String, int>? taskStats,
    this.subscriptionType = SubscriptionType.free,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
  }) : userId = userId ?? uid,
       createdAt = createdAt ?? DateTime.now(),
       taskStats = taskStats ?? {'completed': 0, 'pending': 0, 'overdue': 0};

  bool get isPremiumActive {
    if (subscriptionType != SubscriptionType.premium) {
      return false;
    }

    if (subscriptionEndDate == null) {
      return true;
    }

    return subscriptionEndDate!.isAfter(DateTime.now());
  }

  UserModel copyWith({
    String? uid,
    String? userId,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
    Map<String, int>? taskStats,
    SubscriptionType? subscriptionType,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      taskStats: taskStats ?? this.taskStats,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userId': userId,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'taskStats': taskStats,
      'subscriptionType': subscriptionType.name,
      'subscriptionStartDate':
          subscriptionStartDate != null
              ? Timestamp.fromDate(subscriptionStartDate!)
              : null,
      'subscriptionEndDate':
          subscriptionEndDate != null
              ? Timestamp.fromDate(subscriptionEndDate!)
              : null,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
      }
      return fallback ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return UserModel(
      uid: (map['uid'] ?? map['userId'] ?? '').toString(),
      userId: (map['userId'] ?? map['uid'] ?? '').toString(),
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'],
      photoUrl: map['photoUrl'],
      createdAt: parseDate(map['createdAt']),
      taskStats: Map<String, int>.from(
        map['taskStats'] ?? {'completed': 0, 'pending': 0, 'overdue': 0},
      ),
      subscriptionType: SubscriptionType.values.firstWhere(
        (value) => value.name == map['subscriptionType'],
        orElse: () => SubscriptionType.free,
      ),
      subscriptionStartDate: parseNullableDate(map['subscriptionStartDate']),
      subscriptionEndDate: parseNullableDate(map['subscriptionEndDate']),
    );
  }
}
