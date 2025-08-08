import 'package:flutter/material.dart';

class FreeMessageCardPage extends StatefulWidget {
  const FreeMessageCardPage({super.key});

  @override
  State<FreeMessageCardPage> createState() => _FreeMessageCardPageState();
}

class _FreeMessageCardPageState extends State<FreeMessageCardPage> {
  final List<String> occasions = [
    'Birthday',
    'Anniversary',
    'Father\'s Day',
    'Love and Romance',
    'Wedding',
  ];

  String? selectedOccasion;
  String selectedTemplate = 'On this special day, I wish you...';

  final TextEditingController toController = TextEditingController();
  final TextEditingController fromController = TextEditingController();
  final TextEditingController messageController = TextEditingController(
    text:
        "On this special day, I hope that you get all that your heart desires. Happiness, peace of mind, prosperity and good health. May you get all these together",
  );

  bool hideSenderName = false;

  final Map<String, List<String>> templatesByOccasion = {
    "Birthday": [
      "Wishing you a day full of love and cake!",
      "Happy Birthday! Stay blessed.",
      "Hope your birthday is as amazing as you are!",
    ],
    "Anniversary": [
      "Wishing you love and laughter for years to come.",
      "Happy Anniversary! You both are goals.",
      "Celebrating your beautiful journey together!",
    ],
    "Father's Day": [
      "Happy Father’s Day to the best dad ever!",
      "Thank you for always being my hero.",
      "Dad, your love means the world to me!",
    ],
    "Love and Romance": [
      "You complete my heart.",
      "Every moment with you is magical.",
      "I love you more with every heartbeat.",
    ],
    "Wedding": [
      "Wishing you a lifetime of love and happiness!",
      "Congratulations on your beautiful journey together.",
      "May your love grow stronger with each passing year.",
    ],
  };

  void _showTemplateBottomSheet() {
    if (selectedOccasion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an occasion first")),
      );
      return;
    }

    final templates = templatesByOccasion[selectedOccasion] ?? [];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(Icons.remove, size: 30, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Templates for $selectedOccasion",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...templates.map(
                    (msg) => GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          selectedTemplate = msg;
                          messageController.text = msg;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(msg, style: const TextStyle(fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void showReviewCardPreview({
    required BuildContext context,
    required String to,
    required String message,
    required String from,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Preview",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 350, // You can increase height if needed
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Left blank side
                      Expanded(child: Container(color: Colors.grey.shade300)),
                      // Right side with content
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                to,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cursive',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Flexible(
                                child: SingleChildScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontFamily: 'Cursive',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  from,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    fontFamily: 'Cursive',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Free Message Card")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Occasion",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children:
                  occasions.map((occasion) {
                    final bool selected = selectedOccasion == occasion;
                    return ChoiceChip(
                      label: Text(occasion),
                      selected: selected,
                      onSelected:
                          (_) => setState(() => selectedOccasion = occasion),
                      showCheckmark: false,
                      selectedColor: Colors.green[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.green[800] : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            const Text(
              "Select Message Template",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showTemplateBottomSheet,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.message, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(child: Text(selectedTemplate)),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              "Dear",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: toController,
              decoration: InputDecoration(
                hintText: "Recipient name",
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.green.shade600,
                    width: 1.5,
                  ),
                ),
                fillColor: Colors.white,
                // Set background to white
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              "Message",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: messageController,
              maxLength: 250,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),

            const Text(
              "From",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: fromController,
              decoration: InputDecoration(
                hintText: "Your name",
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.green.shade600,
                    width: 1.5,
                  ),
                ),
                fillColor: Colors.white,
                // White background
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Checkbox(
                  value: hideSenderName,
                  onChanged:
                      (val) => setState(() => hideSenderName = val ?? false),
                  activeColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Don't show my name on the card",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (toController.text.trim().isEmpty ||
                          messageController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please fill both 'Dear' and 'Message' fields to preview.",
                            ),
                          ),
                        );
                        return;
                      }

                      showReviewCardPreview(
                        context: context,
                        to: toController.text.trim(),
                        message: messageController.text.trim(),
                        from: hideSenderName ? "" : fromController.text.trim(),
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye),
                    label: const Text("Preview"),
                  ),
                ),

                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedOccasion == null ||
                          selectedOccasion!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select an occasion."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (toController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter recipient name."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // If all validations pass
                      Navigator.pop(context, {
                        "occasion": selectedOccasion,
                        "templateId": null, // Add this if needed later
                        "dear": toController.text.trim(),
                        "message": messageController.text.trim(),
                        "from": fromController.text.trim(),
                        "hideSenderName": hideSenderName,
                      });
                    },
                    child: const Text("Continue"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
