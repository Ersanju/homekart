import 'package:flutter/cupertino.dart';

class LocationProvider extends ChangeNotifier {
  String? _location;
  String? _pinCode;
  double? _latitude;
  double? _longitude;
  bool _hasCheckedAvailability = false;

  String? get location => _location;

  String? get pinCode => _pinCode;

  double? get latitude => _latitude;

  double? get longitude => _longitude;

  bool get hasCheckedAvailability => _hasCheckedAvailability;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void update({
    required String location,
    required String pinCode,
    required double latitude,
    required double longitude,
  }) {
    _location = location;
    _pinCode = pinCode;
    _latitude = latitude;
    _longitude = longitude;
    _hasCheckedAvailability = true;
    notifyListeners();
  }

  void reset() {
    _location = null;
    _pinCode = null;
    _latitude = null;
    _longitude = null;
    _hasCheckedAvailability = false;
    notifyListeners();
  }
}
