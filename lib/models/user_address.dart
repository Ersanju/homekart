import 'package:cloud_firestore/cloud_firestore.dart';

class UserAddress {
  final String name;
  final String phone;
  final String addressType; // Home, Work, etc.
  final String street; // Street / Locality / Area
  final String area; // House No. / Apartment / Flat
  final String landmark;
  final String pinCode;
  final String city;
  final String state;
  final String country;
  final GeoPoint? location;

  UserAddress({
    required this.name,
    required this.phone,
    required this.addressType,
    required this.street,
    required this.area,
    required this.landmark,
    required this.pinCode,
    required this.city,
    required this.state,
    required this.country,
    this.location,
  });

  factory UserAddress.empty() {
    return UserAddress(
      name: '',
      phone: '',
      addressType: '',
      street: '',
      area: '',
      landmark: '',
      pinCode: '',
      city: '',
      state: '',
      country: '',
      location: null,
    );
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      addressType: json['addressType'] ?? '',
      street: json['street'] ?? '',
      area: json['area'] ?? '',
      landmark: json['landmark'] ?? '',
      pinCode: json['pinCode'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      location: json['location'] != null ? json['location'] as GeoPoint : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'addressType': addressType,
      'street': street,
      'area': area,
      'landmark': landmark,
      'pinCode': pinCode,
      'city': city,
      'state': state,
      'country': country,
      'location': location,
    };
  }
}
