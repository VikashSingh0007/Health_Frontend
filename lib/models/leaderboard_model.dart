class LeaderboardEntry {
  final String userId;
  final String name;
  final String? picture;
  final String email;
  final int steps;
  final int calories;
  final int? heartRate;
  final double? distance;
  final double? weight;
  final double? height;
  final int? activeMinutes;
  final int rank;
  final bool isCurrentUser;
  final DateTime date;

  LeaderboardEntry({
    required this.userId,
    required this.name,
    this.picture,
    required this.email,
    required this.steps,
    required this.calories,
    this.heartRate,
    this.distance,
    this.weight,
    this.height,
    this.activeMinutes,
    required this.rank,
    required this.isCurrentUser,
    required this.date,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      name: json['name'] as String,
      picture: json['picture'] as String?,
      email: json['email'] as String,
      steps: json['steps'] is int ? json['steps'] as int : (json['steps'] as num?)?.toInt() ?? 0,
      calories: json['calories'] is int 
          ? json['calories'] as int 
          : (json['calories'] as num?)?.toInt() ?? 0,
      heartRate: json['heartRate'] is int 
          ? json['heartRate'] as int? 
          : (json['heartRate'] as num?)?.toInt(),
      distance: json['distance'] != null
          ? (json['distance'] is num 
              ? (json['distance'] as num).toDouble()
              : double.tryParse(json['distance'].toString()))
          : null,
      weight: json['weight'] != null
          ? (json['weight'] is num 
              ? (json['weight'] as num).toDouble()
              : double.tryParse(json['weight'].toString()))
          : null,
      height: json['height'] != null
          ? (json['height'] is num 
              ? (json['height'] as num).toDouble()
              : double.tryParse(json['height'].toString()))
          : null,
      activeMinutes: json['activeMinutes'] is int 
          ? json['activeMinutes'] as int? 
          : (json['activeMinutes'] as num?)?.toInt(),
      rank: json['rank'] as int,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class LeaderboardResponse {
  final List<LeaderboardEntry> data;
  final String metric;
  final String currentUserId;

  LeaderboardResponse({
    required this.data,
    required this.metric,
    required this.currentUserId,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>;
    return LeaderboardResponse(
      data: dataList
          .map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      metric: json['metric'] as String,
      currentUserId: json['currentUserId'] as String,
    );
  }
}

