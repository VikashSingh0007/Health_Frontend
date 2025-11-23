import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/health_provider.dart';
import '../models/health_data_model.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'week'; // 'today', 'week', 'month', 'custom'
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForFilter(_selectedFilter);
    });
  }

  void _loadDataForFilter(String filter) {
    final provider = Provider.of<HealthProvider>(context, listen: false);
    final endDate = DateTime.now();
    DateTime startDate;

    switch (filter) {
      case 'today':
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        break;
      case 'week':
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(endDate.year, endDate.month, 1);
        break;
      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          startDate = _customStartDate!;
          final customEnd = _customEndDate!;
          provider.loadHistoryData(startDate: startDate, endDate: customEnd);
          return;
        } else {
          startDate = endDate.subtract(const Duration(days: 7));
        }
        break;
      default:
        startDate = endDate.subtract(const Duration(days: 7));
    }

    provider.loadHistoryData(startDate: startDate, endDate: endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health History'),
        actions: [
          // Button to fetch real data from Google Fit
          TextButton.icon(
            onPressed: () async {
              final apiService = ApiService();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text('Fetching data from Google Fit...'),
                      ),
                    ],
                  ),
                ),
              );
              
              try {
                final result = await apiService.fetchRealDataFromGoogleFit(days: 30);
                Navigator.pop(context); // Close loading dialog
                
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Fetched ${result['fetchedCount']} days of data from Google Fit!',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
                
                // Reload history data
                final provider = Provider.of<HealthProvider>(context, listen: false);
                final endDate = DateTime.now();
                final startDate = endDate.subtract(const Duration(days: 30));
                await provider.loadHistoryData(startDate: startDate, endDate: endDate);
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.cloud_download, color: Colors.white),
            label: const Text(
              'Fetch 30 Days (TEST)',
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadDataForFilter(_selectedFilter);
            },
          ),
        ],
      ),
      body: Consumer<HealthProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.historyData.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.historyData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No history data available',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try fetching health data from dashboard first',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final apiService = ApiService();
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      
                      // Show loading dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const AlertDialog(
                          content: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text('Google Fit se last 30 days ka data fetch ho raha hai...'),
                              ),
                            ],
                          ),
                        ),
                      );
                      
                      try {
                        final result = await apiService.fetchRealDataFromGoogleFit(days: 30);
                        Navigator.pop(context); // Close loading dialog
                        
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '${result['fetchedCount']} days ka data Google Fit se fetch ho gaya!',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        
                        // Reload history data
                        final endDate = DateTime.now();
                        final startDate = endDate.subtract(const Duration(days: 30));
                        await provider.loadHistoryData(startDate: startDate, endDate: endDate);
                      } catch (e) {
                        Navigator.pop(context); // Close loading dialog
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Fetch Last 30 Days from Google Fit (TEST)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  if (provider.error != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Error: ${provider.error}',
                        style: TextStyle(color: Colors.red[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadDataForFilter(_selectedFilter);
            },
            child: Column(
              children: [
                // Filter Chips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Today', 'today'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Week', 'week'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Month', 'month'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Custom', 'custom'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chart
                        _buildStepsChart(provider.historyData),
                        const SizedBox(height: 24),
                        
                        // History List
                        Text(
                          'Daily Records',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...provider.historyData.map((data) => _buildHistoryCard(context, data)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepsChart(List<HealthDataModel> data) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxSteps = data.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
    final chartData = data.reversed.toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Steps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            final date = chartData[value.toInt()].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MMM dd').format(date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.steps.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minY: 0,
                  maxY: maxSteps * 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, HealthDataModel data) {
    final dateStr = DateFormat('MMMM dd, yyyy').format(data.date);
    final isToday = data.date.year == DateTime.now().year &&
        data.date.month == DateTime.now().month &&
        data.date.day == DateTime.now().day;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isToday
            ? BorderSide(color: Colors.blue.withOpacity(0.3), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: isToday ? Colors.blue : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.blue : Colors.grey[900],
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Metrics Grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMetricChip(
                  icon: Icons.directions_walk,
                  label: 'Steps',
                  value: '${data.steps}',
                  color: Colors.blue,
                ),
                if (data.calories != null && data.calories! > 0)
                  _buildMetricChip(
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: '${data.calories}',
                    color: Colors.orange,
                  ),
                if (data.heartRate != null)
                  _buildMetricChip(
                    icon: Icons.favorite,
                    label: 'Heart Rate',
                    value: '${data.heartRate} bpm',
                    color: Colors.red,
                  ),
                if (data.distance != null)
                  _buildMetricChip(
                    icon: Icons.straighten,
                    label: 'Distance',
                    value: '${data.distance!.toStringAsFixed(2)} km',
                    color: Colors.green,
                  ),
                if (data.weight != null)
                  _buildMetricChip(
                    icon: Icons.monitor_weight,
                    label: 'Weight',
                    value: '${data.weight!.toStringAsFixed(1)} kg',
                    color: Colors.purple,
                  ),
                if (data.height != null)
                  _buildMetricChip(
                    icon: Icons.height,
                    label: 'Height',
                    value: '${(data.height! * 100).toStringAsFixed(0)} cm',
                    color: Colors.teal,
                  ),
                if (data.sleepDuration != null)
                  _buildMetricChip(
                    icon: Icons.bedtime,
                    label: 'Sleep',
                    value: '${data.sleepDuration!.toStringAsFixed(1)} hrs',
                    color: Colors.indigo,
                  ),
                if (data.activeMinutes != null)
                  _buildMetricChip(
                    icon: Icons.fitness_center,
                    label: 'Active',
                    value: '${data.activeMinutes} min',
                    color: Colors.deepOrange,
                  ),
                if (data.speed != null)
                  _buildMetricChip(
                    icon: Icons.speed,
                    label: 'Speed',
                    value: '${data.speed!.toStringAsFixed(1)} km/h',
                    color: Colors.cyan,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
          if (value == 'custom') {
            _showCustomDatePicker();
          } else {
            _loadDataForFilter(value);
          }
        }
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[700] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
    );
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
      _loadDataForFilter('custom');
    } else {
      // If cancelled, revert to previous filter
      setState(() {
        _selectedFilter = 'week';
      });
    }
  }
}

