import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/health_data_model.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'location_comparison_screen.dart';
import 'location_selection_screen.dart';
import 'login_screen.dart';
import '../providers/health_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isRefreshing = false;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getProfile();
      setState(() {
        _profileData = profile;
      });
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<HealthProvider>(context, listen: false);
      await provider.loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    try {
      await _apiService.fetchHealthData();
      await _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health data refreshed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _insertTestHeartRate() async {
    setState(() => _isRefreshing = true);
    try {
      final response = await _apiService.insertTestHeartRate(heartRate: 75);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] as String? ?? 'Heart rate data inserted!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Refresh dashboard data immediately (data is already saved to database)
      final provider = Provider.of<HealthProvider>(context, listen: false);
      await provider.loadDashboardData();
      
      // Also trigger a UI update
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inserting heart rate: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
          ),
        ],
      ),
      body: Consumer<HealthProvider>(
        builder: (context, provider, child) {
          if (_isLoading && provider.dashboardData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = provider.dashboardData;
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No health data available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _refreshData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Fetch Health Data'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _insertTestHeartRate,
                    icon: const Icon(Icons.favorite),
                    label: const Text('Add Test Heart Rate (75 bpm)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  if (_profileData != null) _buildProfileHeader(),
                  if (_profileData != null) const SizedBox(height: 20),
                  
                  // Steps Card
                  _buildMetricCard(
                    context,
                    icon: Icons.directions_walk,
                    title: 'Steps Today',
                    value: data.steps > 0 ? '${data.steps}' : '0',
                    subtitle: data.steps > 0 ? 'steps' : 'No data yet',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  
                  // Calories Card
                  _buildMetricCard(
                    context,
                    icon: Icons.local_fire_department,
                    title: 'Calories',
                    value: data.calories != null && data.calories! > 0 
                        ? '${data.calories}' 
                        : '0',
                    subtitle: data.calories != null && data.calories! > 0 
                        ? 'kcal' 
                        : 'No data yet',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  
                  // Heart Rate Card
                  _buildMetricCard(
                    context,
                    icon: Icons.favorite,
                    title: 'Heart Rate',
                    value: data.heartRate != null ? '${data.heartRate}' : '--',
                    subtitle: data.heartRate != null ? 'bpm' : 'Not available',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  
                  // Distance Card
                  _buildMetricCard(
                    context,
                    icon: Icons.straighten,
                    title: 'Distance',
                    value: data.distance != null 
                        ? '${data.distance!.toStringAsFixed(2)}' 
                        : '--',
                    subtitle: data.distance != null ? 'km' : 'Not available',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  
                  // Weight Card
                  _buildMetricCard(
                    context,
                    icon: Icons.monitor_weight,
                    title: 'Weight',
                    value: data.weight != null 
                        ? '${data.weight!.toStringAsFixed(1)}' 
                        : '--',
                    subtitle: data.weight != null ? 'kg' : 'Not available',
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildMetricCard(
                    context,
                    icon: Icons.height,
                    title: 'Height',
                    value: data.height != null 
                        ? '${(data.height! * 100).toStringAsFixed(0)}' 
                        : '--',
                    subtitle: data.height != null ? 'cm' : 'Not available',
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 16),
                  
                  // Sleep Duration Card
                  _buildMetricCard(
                    context,
                    icon: Icons.bedtime,
                    title: 'Sleep',
                    value: data.sleepDuration != null 
                        ? '${data.sleepDuration!.toStringAsFixed(1)}' 
                        : '--',
                    subtitle: data.sleepDuration != null ? 'hours' : 'Not available',
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 16),
                  
                  // Active Minutes Card
                  _buildMetricCard(
                    context,
                    icon: Icons.fitness_center,
                    title: 'Active Minutes',
                    value: data.activeMinutes != null 
                        ? '${data.activeMinutes}' 
                        : '--',
                    subtitle: data.activeMinutes != null ? 'minutes' : 'Not available',
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 16),
                  
                  // Speed Card
                  _buildMetricCard(
                    context,
                    icon: Icons.speed,
                    title: 'Average Speed',
                    value: data.speed != null 
                        ? '${data.speed!.toStringAsFixed(1)}' 
                        : '--',
                    subtitle: data.speed != null ? 'km/h' : 'Not available',
                    color: Colors.cyan,
                  ),
                  const SizedBox(height: 16),
                  
                  // Info Message if no data
                  if (data.steps == 0 && (data.calories == null || data.calories == 0))
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Google Fit se data nahi aa raha',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ya to aaj ke liye Google Fit me activity data nahi hai, ya permission / token expire ho chuka hai. '
                                  'Data aane ke liye Google Fit app me steps/heart data check karein. '
                                  'Agar baar‑baar aisa hi dikh raha hai, ek baar logout karke dobara login karein taaki connection refresh ho jaye.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Fetch Last 30 Days Button (TEST - Remove later)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isRefreshing ? null : () async {
                        setState(() => _isRefreshing = true);
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
                          final result = await _apiService.fetchRealDataFromGoogleFit(days: 30);
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
                          
                          // Reload dashboard data
                          await _loadDashboardData();
                        } catch (e) {
                          Navigator.pop(context); // Close loading dialog
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isRefreshing = false);
                          }
                        }
                      },
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Fetch Last 30 Days from Google Fit (TEST)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Refresh Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isRefreshing ? null : _refreshData,
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_isRefreshing ? 'Refreshing...' : 'Refresh Today\'s Data'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                    // History Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('View History'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Leaderboard Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LeaderboardScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.leaderboard),
                        label: const Text('View Leaderboard'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header with Profile
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[400]!,
                  Colors.purple[400]!,
                ],
              ),
            ),
            child: Column(
              children: [
                // Profile Picture
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _buildProfileAvatar(radius: 50),
                ),
                const SizedBox(height: 16),
                // Name
                Text(
                  _profileData?['name'] as String? ?? 'User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  _profileData?['email'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                  },
                  isSelected: true,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.history,
                  title: 'History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.leaderboard,
                  title: 'Leaderboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaderboardScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.location_city,
                  title: 'Location Comparison',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LocationComparisonScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () async {
                    Navigator.pop(context);
                    await _authService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? (isSelected ? Colors.blue[700] : Colors.grey[700]),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isSelected ? Colors.blue[700] : Colors.grey[900]),
        ),
      ),
      selected: isSelected,
      onTap: onTap,
      selectedTileColor: Colors.blue[50],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[400]!,
            Colors.purple[400]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _buildProfileAvatar(radius: 40),
          ),
          const SizedBox(width: 16),
          // Name and Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profileData?['name'] as String? ?? 'User',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _profileData?['email'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar({double radius = 50}) {
    final pictureUrl = _profileData?['picture'] as String?;
    final name = _profileData?['name'] as String? ?? 'U';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    
    // If no picture URL or empty, show initial
    if (pictureUrl == null || pictureUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
      );
    }
    
    // Use Image.network with error handling instead of NetworkImage directly
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: Image.network(
          pictureUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If image fails to load (429, 404, etc.), show initial
            print('Profile image failed to load: $error');
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            // Show loading indicator while image loads
            return Center(
              child: SizedBox(
                width: radius,
                height: radius,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

