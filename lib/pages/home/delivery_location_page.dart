import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class DeliveryLocationPage extends StatefulWidget {
  const DeliveryLocationPage({super.key});

  @override
  State<DeliveryLocationPage> createState() => _DeliveryLocationPageState();
}

class _DeliveryLocationPageState extends State<DeliveryLocationPage> {
  late GoogleMapController _mapController;
  LatLng _center = const LatLng(27.046192, 82.2315); // Default to Mankapur
  String _address = "Fetching address...";
  String _pinCode = "";
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndInit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Delivery Location")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 16),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
          ),

          // 📍 Center Pin Icon with legacy Material style
          const Center(
            child: Icon(
              Icons.location_pin, // Sharp pin icon
              size: 40,
              color: Colors.red,
            ),
          ),

          // Address Card
          Positioned(
            top: 10,
            left: 20,
            right: 20,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Selected Address",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(_address),
                            if (_pinCode.isNotEmpty)
                              Text(
                                "Pin Code: $_pinCode",
                                style: const TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
              ),
            ),
          ),
        ],
      ),

      // Confirm Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _confirmLocation,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              "Confirm Location",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkPermissionAndInit() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });

      _mapController.animateCamera(CameraUpdate.newLatLng(_center));

      await _updateAddress(_center);
    } else {
      setState(() {
        _address = "Location permission denied.";
        _loading = false;
      });
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    setState(() => _loading = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = "${place.locality}, ${place.administrativeArea}";
        setState(() {
          _address = address;
          _pinCode = place.postalCode ?? '';
        });
      } else {
        setState(() => _address = "Address not found");
      }
    } catch (e) {
      setState(() => _address = "Error retrieving address");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
  }

  void _onCameraIdle() {
    _updateAddress(_center);
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'location': _address,
      'pin': _pinCode,
      'lat': _center.latitude,
      'lng': _center.longitude,
    });
  }
}
