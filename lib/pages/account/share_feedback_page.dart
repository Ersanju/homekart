import 'package:flutter/material.dart';

class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  int _rating = 4;
  String _feedbackLabel = "Good Experience";
  final List<String> labels = ["Very Bad", "Bad", "Okay", "Good Experience", "Excellent"];

  void _updateRating(int index) {
    setState(() {
      _rating = index + 1;
      _feedbackLabel = labels[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const Text(
            "Share your feedback",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Divider(
            thickness: .5,
            color: Colors.grey,
          ),
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.amber,

            child: Icon(Icons.emoji_emotions_outlined, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(_feedbackLabel, style: const TextStyle(fontSize: 16)),
          Text("$_rating/5", style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => _updateRating(index),
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 30,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 130, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context); // Close sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text("Submit", style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
