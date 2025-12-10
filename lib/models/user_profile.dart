/// Model representing a user's profile information including biometric data
/// and skin tone calibration results.
class UserProfile {
  final String name;
  final int age;
  final String gender; // 'Male', 'Female', 'Other'
  final double height; // in cm
  final double weight; // in kg
  final double melaninIndex; // Computed melanin index from skin tone
  final int? lastUpdated; // Timestamp in milliseconds

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.melaninIndex,
    this.lastUpdated,
  });

  /// Convert UserProfile to JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender,
    'height': height,
    'weight': weight,
    'melaninIndex': melaninIndex,
    'lastUpdated': lastUpdated ?? DateTime.now().millisecondsSinceEpoch,
  };

  /// Create UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] as String,
    age: json['age'] as int,
    gender: json['gender'] as String,
    height: (json['height'] as num).toDouble(),
    weight: (json['weight'] as num).toDouble(),
    melaninIndex: (json['melaninIndex'] as num).toDouble(),
    lastUpdated: json['lastUpdated'] as int?,
  );

  /// Create a copy of UserProfile with modified fields
  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? melaninIndex,
    int? lastUpdated,
  }) => UserProfile(
    name: name ?? this.name,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    height: height ?? this.height,
    weight: weight ?? this.weight,
    melaninIndex: melaninIndex ?? this.melaninIndex,
    lastUpdated: lastUpdated ?? DateTime.now().millisecondsSinceEpoch,
  );

  @override
  String toString() => 'UserProfile(name: $name, age: $age, melaninIndex: $melaninIndex)';
}
