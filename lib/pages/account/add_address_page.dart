import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/user_address.dart';
import '../home/delivery_location_page.dart';

class AddAddressPage extends StatefulWidget {
  final void Function(UserAddress) onSave;

  const AddAddressPage({super.key, required this.onSave});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final houseController = TextEditingController();
  final streetController = TextEditingController();
  final landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();

  GeoPoint? _location;
  String? _locality;
  String? _city;
  String? _state;
  String? _country;

  bool _isLocating = false;
  bool _isDeliverable = false;
  String _addressType = 'Home';

  // Delivery zone
  final GeoPoint deliveryCenter = const GeoPoint(27.046, 82.231); // Mankapur
  final double maxDeliveryDistance = 10000; // meters (10km)

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    houseController.dispose();
    streetController.dispose();
    landmarkController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Address"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Receiver’s Contact",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Receiver's Name*",
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  if (!RegExp(r"^[A-Za-z\s]{2,40}$").hasMatch(value.trim())) {
                    return 'Only letters allowed (2–40 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Phone
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Mobile Number*"),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!RegExp(r"^[0-9]{10}$").hasMatch(value)) {
                    return 'Enter valid 10-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              const Text(
                "Receiver’s Address",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // House
              TextFormField(
                controller: houseController,
                decoration: const InputDecoration(
                  labelText: "Flat, House No., Building*",
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              // Street
              TextFormField(
                controller: streetController,
                decoration: const InputDecoration(
                  labelText: "Street, Area, Locality*",
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              // Landmark
              TextFormField(
                controller: landmarkController,
                decoration: const InputDecoration(labelText: "Landmark"),
              ),
              const SizedBox(height: 10),

              // Pincode (auto-filled)
              TextFormField(
                controller: _pincodeController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: "Pincode (Tap to detect location)",
                  hintText: "Tap on 'Use Current Location'",
                ),
              ),
              const SizedBox(height: 10),

              if (_city != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Place: $_locality"),
                    Text("District: $_city"),
                    const SizedBox(height: 10),
                  ],
                ),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLocating ? null : _useCurrentLocation,
                      icon:
                          _isLocating
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.my_location),
                      label: const Text("Use Current Location"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _chooseLocationOnMap,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text("Choose on Map"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              if (_location != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _isDeliverable
                        ? "✅ We deliver to this location"
                        : "❌ Sorry, we do not deliver to this location",
                    style: TextStyle(
                      color: _isDeliverable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              const Text(
                "Address Type",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              Row(
                children:
                    ["Home", "Work", "Other"].map((type) {
                      return Row(
                        children: [
                          Radio<String>(
                            value: type,
                            groupValue: _addressType,
                            onChanged:
                                (val) => setState(() => _addressType = val!),
                          ),
                          Text(type),
                        ],
                      );
                    }).toList(),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_location == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please use current location."),
                        ),
                      );
                      return;
                    }

                    if (!_isDeliverable) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("We do not deliver to this location."),
                        ),
                      );
                      return;
                    }

                    final address = UserAddress(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      addressType: _addressType,
                      street: streetController.text.trim(),
                      area: houseController.text.trim(),
                      landmark: landmarkController.text.trim(),
                      pinCode: _pincodeController.text.trim(),
                      city: _city ?? '',
                      state: _state ?? '',
                      country: _country ?? '',
                      location: _location,
                    );

                    widget.onSave(address);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF787430),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Save & Continue",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _location = GeoPoint(position.latitude, position.longitude);

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _pincodeController.text = place.postalCode ?? '';
          _locality = place.locality ?? '';
          _city = place.subAdministrativeArea ?? '';
          _state = place.administrativeArea ?? '';
          _country = place.country ?? '';
        });

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          deliveryCenter.latitude,
          deliveryCenter.longitude,
        );

        setState(() {
          _isDeliverable = distance <= maxDeliveryDistance;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
    setState(() => _isLocating = false);
  }

  Future<void> _chooseLocationOnMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryLocationPage()),
    );

    if (result != null) {
      final lat = result['lat'] as double;
      final lng = result['lng'] as double;
      final pin = result['pin'] as String?;

      setState(() {
        _location = GeoPoint(lat, lng);
        _pincodeController.text = pin ?? '';
      });

      final distance = Geolocator.distanceBetween(
        lat,
        lng,
        deliveryCenter.latitude,
        deliveryCenter.longitude,
      );

      setState(() {
        _isDeliverable = distance <= maxDeliveryDistance;
        _locality = null;
        _city = null;
        _state = null;
        _country = null;
      });

      // Optionally update city/state/country too using reverse geocoding
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          setState(() {
            _locality = place.locality ?? '';
            _city = place.subAdministrativeArea ?? '';
            _state = place.administrativeArea ?? '';
            _country = place.country ?? '';
          });
        }
      } catch (_) {}
    }
  }
}
