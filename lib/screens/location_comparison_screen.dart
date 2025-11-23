import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class LocationComparisonScreen extends StatefulWidget {
  const LocationComparisonScreen({super.key});

  @override
  State<LocationComparisonScreen> createState() => _LocationComparisonScreenState();
}

class _LocationComparisonScreenState extends State<LocationComparisonScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _locationStats = [];
  bool _isLoading = false;
  String? _error;
  String _selectedMetric = 'steps';
  String _selectedPeriod = 'today'; // 'today', 'week', 'month'

  @override
  void initState() {
    super.initState();
    _loadLocationStats();
  }

  Future<void> _loadLocationStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _apiService.getLocationStatistics(period: _selectedPeriod);
      setState(() {
        _locationStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _switchPeriod(String period) {
    if (period != _selectedPeriod) {
      setState(() {
        _selectedPeriod = period;
      });
      _loadLocationStats();
    }
  }

  void _switchMetric(String metric) {
    setState(() {
      _selectedMetric = metric;
    });
  }

  double _getMetricValue(Map<String, dynamic> stat) {
    if (_selectedMetric == 'steps') {
      return (stat['totalSteps'] as num?)?.toDouble() ?? 0.0;
    } else if (_selectedMetric == 'calories') {
      return (stat['totalCalories'] as num?)?.toDouble() ?? 0.0;
    } else {
      return (stat['totalActiveMinutes'] as num?)?.toDouble() ?? 0.0;
    }
  }

  String _getMetricLabel() {
    switch (_selectedMetric) {
      case 'steps':
        return 'Total Steps';
      case 'calories':
        return 'Total Calories';
      case 'activeMinutes':
        return 'Total Active Minutes';
      default:
        return 'Total Steps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Comparison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadLocationStats,
          ),
        ],
      ),
      body: _isLoading && _locationStats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _locationStats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading location stats',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadLocationStats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _locationStats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_city, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No location data available',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Users need to set their location first',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLocationStats,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Period Filter
                            _buildPeriodSelector(),
                            const SizedBox(height: 16),
                            // Metric Selector
                            _buildMetricSelector(),
                            const SizedBox(height: 24),

                            // Chart
                            _buildChart(),
                            const SizedBox(height: 24),

                            // Location Cards
                            Text(
                              'Location Rankings',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            ..._locationStats.asMap().entries.map((entry) {
                              return _buildLocationCard(entry.value, entry.key + 1);
                            }),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildMetricSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _buildMetricButton('Steps', 'steps', Icons.directions_walk, Colors.blue),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricButton('Calories', 'calories', Icons.local_fire_department, Colors.orange),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricButton('Active', 'activeMinutes', Icons.fitness_center, Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricButton(String label, String metric, IconData icon, Color color) {
    final isSelected = _selectedMetric == metric;
    return InkWell(
      onTap: () => _switchMetric(metric),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_locationStats.isEmpty) return const SizedBox.shrink();

    final maxValue = _locationStats.map((s) => _getMetricValue(s)).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getMetricLabel(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blue,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _locationStats.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _locationStats[value.toInt()]['location'] as String? ?? '',
                                style: const TextStyle(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  barGroups: _locationStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;
                    final value = _getMetricValue(stat);
                    final isTop = index == 0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: isTop ? Colors.amber : Colors.blue,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> stat, int rank) {
    final location = stat['location'] as String? ?? 'Unknown';
    final totalSteps = stat['totalSteps'] as num? ?? 0;
    final totalCalories = stat['totalCalories'] as num? ?? 0;
    final totalActiveMinutes = stat['totalActiveMinutes'] as num? ?? 0;
    final avgSteps = stat['avgSteps'] as num? ?? 0;
    final userCount = stat['userCount'] as num? ?? 0;
    final activeUserCount = stat['activeUserCount'] as num? ?? 0;
    final isTop = rank == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isTop ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isTop
            ? BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Rank Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: isTop
                        ? LinearGradient(
                            colors: [Colors.amber[400]!, Colors.amber[600]!],
                          )
                        : LinearGradient(
                            colors: [Colors.grey[300]!, Colors.grey[400]!],
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank',
                      style: TextStyle(
                        fontSize: rank <= 3 ? 24 : 16,
                        fontWeight: FontWeight.bold,
                        color: isTop ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isTop ? Colors.amber[900] : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$activeUserCount / $userCount active users',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.directions_walk,
                    'Total Steps',
                    totalSteps.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    Icons.local_fire_department,
                    'Total Calories',
                    totalCalories.toString(),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    Icons.fitness_center,
                    'Active Min',
                    totalActiveMinutes.toString(),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Average: ${avgSteps.toString()} steps per user',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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

