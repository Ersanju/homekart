import 'package:flutter/material.dart';

class FYQPage extends StatelessWidget {
  const FYQPage({super.key});

  final List<Map<String, String>> faqItems = const [
    {
      'question': 'Do you deliver only within India or overseas?',
      'answer': 'We deliver both within India and overseas depending on location.'
    },
    {
      'question': 'Can I choose the delivery time?',
      'answer': 'Delivery time can be chosen based on availability during checkout.'
    },
    {
      'question': 'Can I get my order delivered at midnight?',
      'answer': 'Midnight delivery is available in select locations for select items.'
    },
    {
      'question': 'What are the different modes of delivery?',
      'answer': 'Standard, Express, Same-day, and Midnight delivery options are available.'
    },
    {
      'question': 'What are the delivery charges?',
      'answer': 'Delivery charges vary based on the delivery mode and location.'
    },
    {
      'question': 'I don’t want to disclose my personal information to the recipient. Is this possible?',
      'answer': 'Yes, you can choose to keep your details confidential during checkout.'
    },
    {
      'question': 'How do I track my order?',
      'answer': 'You can track your order using the tracking ID sent to your email or app notification.'
    },
    {
      'question': 'What do the different order statuses mean?',
      'answer': 'Order statuses indicate the progress: Ordered, Dispatched, In Transit, Delivered, etc.'
    },
    {
      'question': 'My order is partially delivered.',
      'answer': 'Some items may be shipped separately. Please check your order details.'
    },
    {
      'question': 'Date of delivery has lapsed, when will I get my order or refund?',
      'answer': 'If your order is delayed, please contact support for assistance or refund.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: faqItems.length,
        itemBuilder: (context, index) {
          return FAQTile(item: faqItems[index]);
        },
      ),
    );
  }
}

class FAQTile extends StatefulWidget {
  final Map<String, String> item;

  const FAQTile({super.key, required this.item});

  @override
  State<FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<FAQTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(widget.item['question']!),
      trailing: Icon(_isExpanded ? Icons.remove : Icons.add),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(widget.item['answer']!),
        ),
      ],
      onExpansionChanged: (expanded) {
        setState(() {
          _isExpanded = expanded;
        });
      },
    );
  }
}
