import 'package:flutter/material.dart';
import 'package:homekart/pages/cart/payment_page.dart';
import 'package:homekart/pages/cart/price_details.dart';
import 'package:homekart/pages/cart/step_indicator.dart';
import 'package:provider/provider.dart';

import '../../models/card_message.dart';
import '../../models/cart_item.dart';
import '../../models/user_address.dart';
import '../../utils/cart_provider.dart';
import '../../utils/location_provider.dart';
import '../account/saved_addresses.dart';
import 'cart_item_widget.dart';
import 'free_message_card_page.dart';

class DeliveryDetailsPage extends StatefulWidget {
  final UserAddress? selectedAddress;

  const DeliveryDetailsPage({super.key, required this.selectedAddress});

  @override
  State<DeliveryDetailsPage> createState() => _DeliveryDetailsPageState();
}

class _DeliveryDetailsPageState extends State<DeliveryDetailsPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _priceKey = GlobalKey();

  UserAddress? _selectedAddress;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final Map<String, String> _cakeMessages = {};
  final Map<String, Map<String, dynamic>> _cardMessages = {};

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.selectedAddress;
    final cartProvider = context.read<CartProvider>();
    _cakeMessages.addAll(cartProvider.cakeMessages);
    _cardMessages.addAll(cartProvider.cardMessages);
  }

  void _scrollToPriceDetails() {
    final ctx = _priceKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.cartItems;
    final cakeItems =
        cartItems.where((item) => item.productId.contains("cake")).toList();
    final otherItems =
        cartItems.where((item) => !item.productId.contains("cake")).toList();

    // Combine for ordered display
    final orderedItems = [...cakeItems, ...otherItems];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Details'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  const StepIndicator(currentStep: 2),
                  _buildDeliveryBox(context),
                  ListView.builder(
                    itemCount: orderedItems.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item = orderedItems[index];
                      final isCake = item.productId.contains("cake");

                      return CartItemWidget(
                        item: item,
                        onIncrease:
                            () => cartProvider.addItem(
                              item.variant,
                              productId: item.productId,
                              productName: item.productName,
                              productImage: item.productImage,
                              price: item.price,
                            ),
                        onDecrease: () => cartProvider.removeItem(item.variant),
                        onCakeMessageTap:
                            isCake
                                ? () => _showCakeMessageDialog(item.productId)
                                : null,
                        cakeMessage:
                            isCake ? _cakeMessages[item.productId] : null,
                        onCardMessageTap:
                            isCake
                                ? () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => const FreeMessageCardPage(),
                                    ),
                                  );
                                  if (result is Map<String, dynamic>) {
                                    final message = CardMessage.fromJson(
                                      result,
                                    );

                                    setState(() {
                                      _cardMessages[item.productId] =
                                          result; // Save as Map<String, dynamic>
                                    });

                                    // ✅ Use a different name to avoid shadowing
                                    final currentItem = cartProvider.cartItems
                                        .firstWhere(
                                          (e) => e.productId == item.productId,
                                          orElse: () => CartItem.empty(),
                                        );

                                    if (currentItem.variant.isNotEmpty) {
                                      await cartProvider.updateCardMessage(
                                        currentItem.variant,
                                        message,
                                      );
                                    }
                                  }
                                }
                                : null,

                        cardMessageData:
                            isCake ? _cardMessages[item.productId] : null,
                      );
                    },
                  ),
                  PriceDetails(
                    key: _priceKey,
                    productPrice: cartProvider.productPrice,
                    discount: cartProvider.discount,
                    deliveryCharge: cartProvider.deliveryCharge,
                    convenienceCharge: cartProvider.convenienceCharge,
                    showCouponField: true, // ✅ show here only
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(context, cartProvider),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cartProvider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _scrollToPriceDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₹${cartProvider.total}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "View price details",
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  (_selectedAddress != null &&
                          _selectedDate != null &&
                          _selectedTimeSlot != null)
                      ? Colors.green.shade400
                      : Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed:
                (_selectedAddress != null &&
                        _selectedDate != null &&
                        _selectedTimeSlot != null)
                    ? () {
                      final cartItems = context.read<CartProvider>().cartItems;
                      final isValid = _validateCakeMessages(cartItems);
                      if (isValid) {
                        _goToPaymentPage();
                      }
                    }
                    : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            "Please select delivery location, date and time before proceeding.",
                          ),
                        ),
                      );
                    },
            child: const Text(
              "Proceed to Pay",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryBox(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Delivery Location, Date & Time",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildDeliveryLocationTile(context),
          const SizedBox(height: 12),
          _buildDeliveryDateTimePicker(),
        ],
      ),
    );
  }

  Widget _buildDeliveryLocationTile(BuildContext context) {
    final provider = context.watch<LocationProvider>();

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child:
                _selectedAddress == null
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Deliver to:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          provider.pinCode ?? 'Not selected',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Deliver to: ${_selectedAddress!.name}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "${_selectedAddress!.area}, ${_selectedAddress!.street}, ${_selectedAddress!.city} - ${_selectedAddress!.pinCode}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
          ),
          OutlinedButton(
            onPressed: () async {
              final selected = await Navigator.push<UserAddress>(
                context,
                MaterialPageRoute(builder: (_) => const SavedAddressesPage()),
              );
              if (selected != null) {
                setState(() => _selectedAddress = selected);
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            child: Text(_selectedAddress == null ? "Add Address" : "Change"),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildDatePickerButton(),
            const SizedBox(width: 10),
            _buildTimeSlotPickerButton(),
          ],
        ),
        if (_selectedDate != null && _selectedTimeSlot != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "Selected: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} • $_selectedTimeSlot",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDatePickerButton() {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: now,
            lastDate: now.add(const Duration(days: 30)),
          );
          if (picked != null) {
            setState(() {
              _selectedDate = picked;
              _selectedTimeSlot = null;
            });
          }
        },
        icon: const Icon(Icons.date_range),
        label: Text(
          _selectedDate != null
              ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
              : "Pick Date",
        ),
        style: _pickerButtonStyle(),
      ),
    );
  }

  Widget _buildTimeSlotPickerButton() {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () async {
          if (_selectedDate == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please select a date first")),
            );
            return;
          }
          final slots = _generateTimeSlotsForDate(_selectedDate!);
          final selected = await showModalBottomSheet<String>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder:
                (context) => ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  children:
                      slots
                          .map(
                            (slot) => ListTile(
                              title: Text(slot),
                              onTap: () => Navigator.pop(context, slot),
                            ),
                          )
                          .toList(),
                ),
          );
          if (selected != null) {
            setState(() => _selectedTimeSlot = selected);
          }
        },
        icon: const Icon(Icons.access_time),
        label: Text(_selectedTimeSlot ?? "Pick Time Slot"),
        style: _pickerButtonStyle(),
      ),
    );
  }

  ButtonStyle _pickerButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.grey),
      ),
    );
  }

  List<String> _generateTimeSlotsForDate(DateTime date) {
    final now = DateTime.now();
    final slots = <String>[];

    for (int hour = 10; hour < 22; hour++) {
      final slotTime = DateTime(date.year, date.month, date.day, hour);
      final label = "${_formatTime(hour)} – ${_formatTime(hour + 1)}";

      if (slotTime.isAfter(now.add(const Duration(hours: 2))) ||
          date.day != now.day ||
          date.month != now.month ||
          date.year != now.year) {
        slots.add(label);
      }
    }
    return slots;
  }

  String _formatTime(int hour) {
    final h = hour > 12 ? hour - 12 : hour;
    final suffix = hour >= 12 ? "PM" : "AM";
    return "${h.toString().padLeft(2, '0')}:00 $suffix";
  }

  void _showCakeMessageDialog(String productId) {
    final cartProvider = context.read<CartProvider>();

    final controller = TextEditingController(
      text: _cakeMessages[productId] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Message on Cake"),
            content: TextField(
              controller: controller,
              maxLength: 30,
              decoration: const InputDecoration(
                hintText: "Enter message (max 30 characters)",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final message = controller.text.trim();

                  setState(() {
                    _cakeMessages[productId] = message;
                  });

                  Navigator.pop(context);

                  // ✅ Save to Firestore
                  final item = cartProvider.cartItems.firstWhere(
                    (e) => e.productId == productId,
                    orElse: () => CartItem.empty(),
                  );

                  if (item.variant.isNotEmpty) {
                    await cartProvider.updateCakeMessage(item.variant, message);
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  bool _validateCakeMessages(List cartItems) {
    final cakeItems = cartItems.where(
      (item) => item.productId.contains("cake"),
    );
    final missing = <String>[];

    for (var item in cakeItems) {
      final msg = _cakeMessages[item.productId];
      final card = _cardMessages[item.productId];

      if (msg == null || msg.isEmpty) missing.add("Cake Message");
      if (card == null) missing.add("Greeting Card");

      if (missing.isNotEmpty) break; // check only once
    }

    if (missing.isNotEmpty) {
      final message =
          "You haven’t added ${missing.toSet().join(" or ")} for some items.\nDo you want to proceed without it?";

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Incomplete Info"),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _goToPaymentPage(); // Continue to payment
                  },
                  child: const Text("Proceed Anyway"),
                ),
              ],
            ),
      );
      return false;
    }

    return true;
  }

  void _goToPaymentPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PaymentPage(
              selectedAddress: _selectedAddress!,
              selectedDate: _selectedDate!,
              selectedTimeSlot: _selectedTimeSlot!,
            ),
      ),
    );
  }
}
