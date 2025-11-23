import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/health_data_model.dart';
import '../services/api_service.dart';

class HealthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  DashboardData? _dashboardData;
  List<HealthDataModel> _historyData = [];
  bool _isLoading = false;
  String? _error;

  DashboardData? get dashboardData => _dashboardData;
  List<HealthDataModel> get historyData => _historyData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Helper method to safely notify listeners after build phase
  void _safeNotifyListeners() {
    Future.microtask(() => notifyListeners());
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      print('Loading dashboard data...');
      _dashboardData = await _apiService.getDashboardData();
      print('Dashboard data loaded: ${_dashboardData?.steps} steps, ${_dashboardData?.heartRate} bpm');
      _error = null;
    } catch (e) {
      print('Error loading dashboard data: $e');
      _error = e.toString();
      _dashboardData = null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadHistoryData({DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      print('Loading history data from ${startDate?.toIso8601String()} to ${endDate?.toIso8601String()}');
      _historyData = await _apiService.getHealthHistory(
        startDate: startDate,
        endDate: endDate,
      );
      print('History data loaded: ${_historyData.length} records');
      _error = null;
    } catch (e) {
      print('Error loading history data: $e');
      _error = e.toString();
      _historyData = [];
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> refreshData() async {
    try {
      await _apiService.fetchHealthData();
      await loadDashboardData();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
    }
  }
}

