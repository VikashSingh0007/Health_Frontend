class HealthDataModel {
  final String id;
  final String userId;
  final int steps;
  final int? heartRate;
  final int? calories;
  final double? distance;
  final double? weight;
  final double? height;
  final double? sleepDuration;
  final int? activeMinutes;
  final double? speed;
  final DateTime fetchedAt;
  final DateTime date;

  HealthDataModel({
    required this.id,
    required this.userId,
    required this.steps,
    this.heartRate,
    this.calories,
    this.distance,
    this.weight,
    this.height,
    this.sleepDuration,
    this.activeMinutes,
    this.speed,
    required this.fetchedAt,
    required this.date,
  });

  factory HealthDataModel.fromJson(Map<String, dynamic> json) {
    // Helper function to convert string or num to double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Helper function to parse date (handles both string and DateTime)
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      throw Exception('Invalid date format: $value');
    }

    return HealthDataModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      steps: json['steps'] is int ? json['steps'] as int : (json['steps'] as num?)?.toInt() ?? 0,
      heartRate: json['heart_rate'] is int 
          ? json['heart_rate'] as int? 
          : (json['heart_rate'] as num?)?.toInt(),
      calories: json['calories'] is int 
          ? json['calories'] as int? 
          : (json['calories'] as num?)?.toInt(),
      distance: parseDouble(json['distance']),
      weight: parseDouble(json['weight']),
      height: parseDouble(json['height']),
      sleepDuration: parseDouble(json['sleep_duration']),
      activeMinutes: json['active_minutes'] is int 
          ? json['active_minutes'] as int? 
          : (json['active_minutes'] as num?)?.toInt(),
      speed: parseDouble(json['speed']),
      fetchedAt: parseDate(json['fetched_at']),
      date: parseDate(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'steps': steps,
      'heart_rate': heartRate,
      'calories': calories,
      'distance': distance,
      'weight': weight,
      'height': height,
      'sleep_duration': sleepDuration,
      'active_minutes': activeMinutes,
      'speed': speed,
      'fetched_at': fetchedAt.toIso8601String(),
      'date': date.toIso8601String(),
    };
  }
}

class DashboardData {
  final int steps;
  final int? calories;
  final int? heartRate;
  final double? distance;
  final double? weight;
  final double? height;
  final double? sleepDuration;
  final int? activeMinutes;
  final double? speed;
  final DateTime? date;

  DashboardData({
    required this.steps,
    this.calories,
    this.heartRate,
    this.distance,
    this.weight,
    this.height,
    this.sleepDuration,
    this.activeMinutes,
    this.speed,
    this.date,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    // Helper function to convert string or num to double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Helper function to parse date (handles both string and DateTime)
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return DashboardData(
      steps: json['steps'] is int ? json['steps'] as int : (json['steps'] as num?)?.toInt() ?? 0,
      calories: json['calories'] is int 
          ? json['calories'] as int? 
          : (json['calories'] as num?)?.toInt(),
      heartRate: json['heartRate'] is int 
          ? json['heartRate'] as int? 
          : (json['heartRate'] as num?)?.toInt(),
      distance: parseDouble(json['distance']),
      weight: parseDouble(json['weight']),
      height: parseDouble(json['height']),
      sleepDuration: parseDouble(json['sleepDuration']),
      activeMinutes: json['activeMinutes'] is int 
          ? json['activeMinutes'] as int? 
          : (json['activeMinutes'] as num?)?.toInt(),
      speed: parseDouble(json['speed']),
      date: parseDate(json['date']),
    );
  }
}

