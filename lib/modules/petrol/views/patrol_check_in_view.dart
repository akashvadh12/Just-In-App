import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:security_guard/core/theme/app_colors.dart';
import 'package:security_guard/core/theme/app_text_styles.dart';

class PatrolCheckInScreen extends StatefulWidget {
  const PatrolCheckInScreen({super.key});

  @override
  State<PatrolCheckInScreen> createState() => _PatrolCheckInScreenState();
}

class _PatrolCheckInScreenState extends State<PatrolCheckInScreen> {
  int _currentStep = 1;
  LatLng? _currentLatLng;
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final locationPermission = await Permission.location.request();
    if (!locationPermission.isGranted) return;

    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);

    setState(() => _currentLatLng = latLng);

    if (_isMapReady) {
      _mapController.move(latLng, 16);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isMapReady && _currentLatLng != null) {
          _mapController.move(_currentLatLng!, 16);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrol Check-in'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        titleTextStyle: AppTextStyles.heading.copyWith(color: AppColors.whiteColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProgressBar(),
            _buildMapView(),
            _buildLocationOptions(),
            _buildVerificationSection(),
            _buildPhotoSection(),
            _buildNotesSection(),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.whiteColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildProgressStep(1, 'Location', true),
          _buildProgressStep(2, 'Verify', true),
          _buildProgressStep(3, 'Photo', false),
          _buildProgressStep(4, 'Submit', false),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primary : AppColors.lightGrey,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: AppColors.whiteColor)
                : Text(
                    step.toString(),
                    style: AppTextStyles.body.copyWith(
                      color: isCompleted ? AppColors.whiteColor : AppColors.greyColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.subtitle),
      ],
    );
  }

  Widget _buildMapView() {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          _currentLatLng == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLatLng!,
                    initialZoom: 16.0,
                    onMapReady: () {
                      setState(() {
                        _isMapReady = true;
                      });
                      if (_currentLatLng != null) {
                        _mapController.move(_currentLatLng!, 16);
                      }
                    },
                    onTap: (tapPosition, point) {
                      setState(() => _currentLatLng = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.security_guard',
                    ),
                    if (_currentLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLatLng!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
          Positioned(
            top: 10,
            right: 10,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.whiteColor,
                foregroundColor: AppColors.primary,
                elevation: 2,
              ),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => _buildLocationList(),
              ),
              child: const Text("List View"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationList() {
    final locations = ['Main Gate', 'Backyard', 'Warehouse Entry', 'Parking Lot'];
    return ListView.builder(
      itemCount: locations.length,
      itemBuilder: (_, index) => ListTile(
        leading: const Icon(Icons.place),
        title: Text(locations[index]),
        onTap: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildLocationOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLocationOption(Icons.qr_code_scanner, 'Scan QR Code', 'Scan point marker'),
          _buildLocationOption(Icons.location_on, 'Manual Select', 'Choose from list'),
        ],
      ),
    );
  }

  Widget _buildLocationOption(IconData icon, String title, String subtitle) {
    return Container(
      width: 170,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.whiteColor),
          ),
          const SizedBox(height: 8),
          Text(title, style: AppTextStyles.subtitle),
          Text(subtitle, style: AppTextStyles.hint),
        ],
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(8)),
      child: const ListTile(
        leading: Icon(Icons.gps_fixed, color: AppColors.primary),
        title: Text('Verify Location'),
        subtitle: Text('Check geo-fence'),
        trailing: Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(color: const Color(0xFF222831), borderRadius: BorderRadius.circular(8)),
            child: const Center(
              child: Icon(Icons.camera_alt, color: AppColors.greyColor, size: 48),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.flash_on, color: AppColors.greyColor),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: AppColors.whiteColor, size: 30),
              ),
              const Icon(Icons.refresh, color: AppColors.greyColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(8)),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Add patrol notes (optional)',
          hintStyle: AppTextStyles.hint,
          border: InputBorder.none,
        ),
        maxLines: 3,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text('Submit Patrol Report', style: AppTextStyles.subtitle.copyWith(color: AppColors.whiteColor)),
      ),
    );
  }
}
