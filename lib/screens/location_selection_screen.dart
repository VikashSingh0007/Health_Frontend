import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class LocationSelectionScreen extends StatefulWidget {
  final String? currentLocation;
  
  const LocationSelectionScreen({
    super.key,
    this.currentLocation,
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  // OpenStreetMap Nominatim API (Free, no API key needed)
  static const String _nominatimApiUrl = 'https://nominatim.openstreetmap.org/search';
  
  List<Map<String, String>> _placeSuggestions = []; // {description: "City, State", placeId: "..."}
  String? _selectedLocation;
  bool _isSaving = false;
  bool _showSuggestions = true;
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
    _searchController.text = widget.currentLocation ?? '';
    _searchController.addListener(_filterLocations);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLocations);
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _filterLocations() {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _placeSuggestions = [];
        _showSuggestions = false;
        _selectedLocation = null;
        _isSearching = false;
      });
      return;
    }
    
    // Debounce search - wait 500ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _placeSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // OpenStreetMap Nominatim API call (Free, no API key needed)
      // Removed countrycodes=in to allow worldwide search
      final url = Uri.parse(
        '$_nominatimApiUrl?q=${Uri.encodeComponent(query)}&format=json&limit=10&addressdetails=1'
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'HealthTrackerApp/1.0', // Required by Nominatim
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        
        setState(() {
          if (data.isNotEmpty) {
            _placeSuggestions = data.map((place) {
              final address = place['address'] as Map<String, dynamic>? ?? {};
              final displayName = place['display_name'] as String? ?? '';
              
              // Create a clean location name
              String locationName = displayName;
              
              // Try to get city/state for cleaner name
              if (address.containsKey('city')) {
                locationName = address['city'] as String;
                if (address.containsKey('state')) {
                  locationName += ', ${address['state']}';
                }
              } else if (address.containsKey('town')) {
                locationName = address['town'] as String;
                if (address.containsKey('state')) {
                  locationName += ', ${address['state']}';
                }
              } else if (address.containsKey('village')) {
                locationName = address['village'] as String;
                if (address.containsKey('state')) {
                  locationName += ', ${address['state']}';
                }
              } else if (address.containsKey('state_district')) {
                locationName = address['state_district'] as String;
              }
              
              return {
                'description': locationName,
                'placeId': place['place_id']?.toString() ?? 'custom',
                'fullName': displayName, // Keep full name for reference
              };
            }).toList();
            
            // Add custom option at top if query doesn't match exactly
            if (!_placeSuggestions.any((p) => 
                p['description']!.toLowerCase() == query.toLowerCase())) {
              _placeSuggestions.insert(0, {
                'description': query,
                'placeId': 'custom',
                'fullName': query,
              });
            }
          } else {
            // No results - show custom option
            _placeSuggestions = [{
              'description': query,
              'placeId': 'custom',
              'fullName': query,
            }];
          }
          
          _isSearching = false;
          _showSuggestions = true;
        });
      } else {
        // HTTP error - show custom option
        setState(() {
          _placeSuggestions = [{
            'description': query,
            'placeId': 'custom',
            'fullName': query,
          }];
          _isSearching = false;
          _showSuggestions = true;
        });
      }
    } catch (e) {
      // Network error - show custom option
      setState(() {
        _placeSuggestions = [{
          'description': query,
          'placeId': 'custom',
          'fullName': query,
        }];
        _isSearching = false;
        _showSuggestions = true;
      });
    }
  }

  Future<void> _saveLocation() async {
    final location = _searchController.text.trim();
    
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _apiService.updateProfile(location: location);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location "$location" saved successfully!')),
        );
        Navigator.pop(context, location);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _selectLocation(String location) {
    setState(() {
      _selectedLocation = location;
      _searchController.text = location;
      _showSuggestions = false;
      _placeSuggestions = [];
    });
    // Close keyboard
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search or type your office location',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Search TextField
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search or type location...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _selectedLocation = null;
                                _showSuggestions = true;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    _filterLocations();
                  },
                  onTap: () {
                    setState(() {
                      _showSuggestions = true;
                    });
                  },
                ),
              ],
            ),
          ),

          // Suggestions List
          Expanded(
            child: _isSearching
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Searching locations...'),
                        ],
                      ),
                    ),
                  )
                : _showSuggestions && _searchController.text.isNotEmpty
                    ? _buildSuggestionsList()
                    : _buildEmptyState(),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _searchController.text.trim().isEmpty
                            ? 'Enter Location'
                            : 'Save "${_searchController.text.trim()}"',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_placeSuggestions.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No locations found',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Search Results',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        
        // Place Suggestions
        ..._placeSuggestions.asMap().entries.map((entry) {
          final index = entry.key;
          final place = entry.value;
          final description = place['description']!;
          final isCustom = place['placeId'] == 'custom';
          final isSelected = _selectedLocation == description;
          
          return Card(
            margin: EdgeInsets.only(bottom: index == _placeSuggestions.length - 1 ? 0 : 8),
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected
                  ? BorderSide(color: Colors.blue, width: 2)
                  : isCustom
                      ? BorderSide(color: Colors.green[300]!, width: 1.5)
                      : BorderSide.none,
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCustom 
                      ? Colors.green[50] 
                      : isSelected 
                          ? Colors.blue[50] 
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCustom ? Icons.add_location : Icons.location_on,
                  color: isCustom 
                      ? Colors.green[700] 
                      : isSelected 
                          ? Colors.blue 
                          : Colors.grey[600],
                ),
              ),
              title: Text(
                description,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey[900],
                  fontSize: 15,
                ),
              ),
              subtitle: isCustom
                  ? const Text(
                      'Custom location',
                      style: TextStyle(fontSize: 12),
                    )
                  : place['fullName'] != null && place['fullName'] != place['description']
                      ? Text(
                          place['fullName'] as String,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: Colors.blue)
                  : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              onTap: () => _selectLocation(description),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Search for a Location',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Type any city, area, or location name above',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Powered by OpenStreetMap',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
