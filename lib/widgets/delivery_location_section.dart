import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../pages/home/delivery_location_page.dart';
import '../utils/location_provider.dart';

class DeliveryLocationSection extends StatelessWidget {
  final double storeLat;
  final double storeLng;
  final double deliveryRadiusKm;

  const DeliveryLocationSection({
    super.key,
    this.storeLat = 27.046,
    this.storeLng = 82.231,
    this.deliveryRadiusKm = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<LocationProvider>().isLoading;

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: isLoading,
          child: Opacity(
            opacity: isLoading ? 0.4 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeliveryLocationTile(context),
                const SizedBox(height: 8),
                _buildDeliveryAvailabilityMessage(context),
              ],
            ),
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Center(
              child: Container(
                color: Colors.white.withOpacity(0.6),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeliveryLocationTile(BuildContext context) {
    final provider = context.watch<LocationProvider>();
    final hasLocation = provider.location != null && provider.pinCode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Deliver to:",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            _showLocationOptions(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF77810D)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasLocation
                        ? '${provider.pinCode}, ${provider.location}'
                        : 'Check delivery availability',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: hasLocation ? Colors.black87 : Colors.blue,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black45),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAvailabilityMessage(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();

    if (!locationProvider.hasCheckedAvailability) {
      return const SizedBox.shrink();
    }

    if (locationProvider.latitude == null ||
        locationProvider.longitude == null) {
      return const SizedBox.shrink(); // or a fallback message
    }

    final double distanceInKm =
        Geolocator.distanceBetween(
          storeLat,
          storeLng,
          locationProvider.latitude!,
          locationProvider.longitude!,
        ) /
        1000;

    final bool isDeliverable = distanceInKm <= deliveryRadiusKm;

    return Row(
      children: [
        Icon(
          isDeliverable ? Icons.check_circle : Icons.cancel,
          color: isDeliverable ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          isDeliverable
              ? "Delivery available at your location"
              : "Delivery not available at your location",
          style: TextStyle(
            color: isDeliverable ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showLocationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Text(
                  "Update Delivery Location",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.my_location,
                    color: Colors.deepPurple,
                  ),
                  title: const Text("Use Current Location"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _detectAndSetCurrentLocation(context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.map_outlined,
                    color: Colors.deepPurple,
                  ),
                  title: const Text("Choose location on Map"),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeliveryLocationPage(),
                      ),
                    );
                    if (result != null && context.mounted) {
                      context.read<LocationProvider>().update(
                        location: result['location'],
                        pinCode: result['pin'],
                        latitude: result['lat'],
                        longitude: result['lng'],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _detectAndSetCurrentLocation(BuildContext context) async {
    final locationProvider = context.read<LocationProvider>();
    try {
      locationProvider.setLoading(true);

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locationText = "${place.locality}, ${place.administrativeArea}";
        final pinCode = place.postalCode ?? '';

        locationProvider.update(
          location: locationText,
          pinCode: pinCode,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching location: $e")));
    } finally {
      locationProvider.setLoading(false);
    }
  }
}
