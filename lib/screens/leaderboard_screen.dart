import 'package:flutter/material.dart';
import '../models/leaderboard_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  LeaderboardResponse? _leaderboardData;
  bool _isLoading = false;
  String _selectedMetric = 'steps';
  String _selectedPeriod = 'today'; // 'today', 'week', 'month'
  String? _error;
  String? _currentUserId;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadCurrentUserId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLeaderboard();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    // Get current user ID from stored token or profile
    // For now, we'll get it from the leaderboard response
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getLeaderboard(
        metric: _selectedMetric,
        limit: 50,
        period: _selectedPeriod,
      );
      
      setState(() {
        _leaderboardData = response;
        _currentUserId = response.currentUserId;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _switchPeriod(String period) {
    if (period != _selectedPeriod) {
      _animationController.reset();
      setState(() {
        _selectedPeriod = period;
      });
      _loadLeaderboard();
    }
  }

  void _switchMetric(String metric) {
    if (metric != _selectedMetric) {
      _animationController.reset();
      setState(() {
        _selectedMetric = metric;
      });
      _loadLeaderboard();
    }
  }

  String _getMedalEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey[300]!;
    }
  }

  LinearGradient _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xFFE8E8E8), Color(0xFFC0C0C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 3:
        return const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [Colors.grey[200]!, Colors.grey[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: _isLoading ? null : _loadLeaderboard,
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading && _leaderboardData == null
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null && _leaderboardData == null
                        ? _buildErrorState()
                        : _leaderboardData == null || _leaderboardData!.data.isEmpty
                            ? _buildEmptyState()
                            : _buildLeaderboardContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadLeaderboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.leaderboard, size: 64, color: Colors.blue[300]),
            ),
            const SizedBox(height: 24),
            Text(
              'No Leaderboard Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to add health data\nand climb to the top!',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    return FadeTransition(
      opacity: _animationController,
      child: RefreshIndicator(
        onRefresh: _loadLeaderboard,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Period Filter
                            _buildPeriodSelector(),
                            const SizedBox(height: 16),
                            // Metric Selector
                            _buildMetricSelector(),
                            const SizedBox(height: 20),

              // Top 3 Podium
              if (_leaderboardData!.data.length >= 3)
                _buildTopThreePodium(),
              const SizedBox(height: 24),

              // Leaderboard List Header
              Row(
                children: [
                  Icon(Icons.list, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'All Rankings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Leaderboard List
              ..._leaderboardData!.data.asMap().entries.map((entry) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (entry.key * 50)),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildLeaderboardCard(entry.value),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricButton(
              'Steps',
              'steps',
              Icons.directions_walk,
              Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[200],
          ),
          Expanded(
            child: _buildMetricButton(
              'Calories',
              'calories',
              Icons.local_fire_department,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricButton(String label, String metric, IconData icon, Color color) {
    final isSelected = _selectedMetric == metric;
    return InkWell(
      onTap: () => _switchMetric(metric),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? color : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : Colors.grey[600],
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopThreePodium() {
    final topThree = _leaderboardData!.data.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue[50]!,
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              if (topThree.length >= 2)
                Expanded(
                  child: _buildPodiumEntry(topThree[1], 2, height: 110),
                ),
              // 1st Place
              if (topThree.isNotEmpty)
                Expanded(
                  child: _buildPodiumEntry(topThree[0], 1, height: 140),
                ),
              // 3rd Place
              if (topThree.length >= 3)
                Expanded(
                  child: _buildPodiumEntry(topThree[2], 3, height: 90),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumEntry(LeaderboardEntry entry, int rank, {required double height}) {
    final value = _selectedMetric == 'steps' ? entry.steps : entry.calories;
    final isCurrentUser = entry.isCurrentUser;

    return Column(
      children: [
        // Medal with animation
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 500 + (rank * 100)),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _getRankGradient(rank),
              boxShadow: [
                BoxShadow(
                  color: _getRankColor(rank).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _getMedalEmoji(rank),
              style: const TextStyle(fontSize: 36),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Avatar with border
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isCurrentUser
                ? LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[600]!],
                  )
                : null,
            border: Border.all(
              color: isCurrentUser ? Colors.blue : Colors.grey[300]!,
              width: isCurrentUser ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isCurrentUser ? Colors.blue : Colors.grey)!.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
            backgroundImage: entry.picture != null ? NetworkImage(entry.picture!) : null,
            child: entry.picture == null
                ? Text(
                    entry.name[0].toUpperCase(),
                    style: TextStyle(
                      color: isCurrentUser ? Colors.blue[900] : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),
        
        // Name
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.blue[50] : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            entry.name.split(' ').first,
            style: TextStyle(
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
              color: isCurrentUser ? Colors.blue[900] : Colors.grey[900],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        
        // Value Podium
        Container(
          height: height,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: _getRankGradient(rank),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentUser ? Colors.blue : _getRankColor(rank),
              width: isCurrentUser ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getRankColor(rank).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.blue[900] : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedMetric == 'steps' ? 'steps' : 'kcal',
                style: TextStyle(
                  fontSize: 11,
                  color: isCurrentUser ? Colors.blue[700] : Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry) {
    final value = _selectedMetric == 'steps' ? entry.steps : entry.calories;
    final isCurrentUser = entry.isCurrentUser;
    final medal = _getMedalEmoji(entry.rank);
    final isTopThree = entry.rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isCurrentUser
            ? LinearGradient(
                colors: [Colors.blue[50]!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isCurrentUser ? null : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isCurrentUser
                ? Colors.blue.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: isCurrentUser ? 15 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: isCurrentUser
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: isTopThree
                        ? _getRankGradient(entry.rank)
                        : LinearGradient(
                            colors: [Colors.grey[300]!, Colors.grey[400]!],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isTopThree ? _getRankColor(entry.rank) : Colors.grey)!
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      medal.isNotEmpty ? medal : '#${entry.rank}',
                      style: TextStyle(
                        fontSize: medal.isNotEmpty ? 24 : 16,
                        fontWeight: FontWeight.bold,
                        color: isTopThree ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Avatar
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrentUser ? Colors.blue : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
                        backgroundImage: entry.picture != null ? NetworkImage(entry.picture!) : null,
                        child: entry.picture == null
                            ? Text(
                                entry.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: isCurrentUser ? Colors.blue[900] : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (isCurrentUser)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Name and Rank
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: TextStyle(
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                          color: isCurrentUser ? Colors.blue[900] : Colors.grey[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 14,
                            color: isCurrentUser ? Colors.blue[700] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Rank #${entry.rank}',
                            style: TextStyle(
                              color: isCurrentUser ? Colors.blue[700] : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Value
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCurrentUser
                          ? [Colors.blue[400]!, Colors.blue[600]!]
                          : [Colors.grey[200]!, Colors.grey[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isCurrentUser ? Colors.blue : Colors.grey)!
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      Text(
                        _selectedMetric == 'steps' ? 'steps' : 'kcal',
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrentUser ? Colors.white70 : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodButton('Today', 'today', Icons.today),
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
            child: _buildPeriodButton('Week', 'week', Icons.date_range),
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
            child: _buildPeriodButton('Month', 'month', Icons.calendar_month),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period, IconData icon) {
    final isSelected = _selectedPeriod == period;
    return InkWell(
      onTap: () => _switchPeriod(period),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
