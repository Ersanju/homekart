import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:homekart/pages/account/reminder_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/reminder_model.dart';
import '../../utils/app_auth_provider.dart';

class ReminderListPage extends StatefulWidget {
  const ReminderListPage({super.key});

  @override
  State<ReminderListPage> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends State<ReminderListPage> {
  late String userId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AppAuthProvider>();
    userId = auth.userId;
  }

  Future<List<Reminder>> _fetchReminders() async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('reminders')
            .orderBy('date')
            .get();

    return querySnapshot.docs
        .map((doc) => Reminder.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Reminder>>(
      future: _fetchReminders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final reminders = snapshot.data ?? [];

        if (reminders.isEmpty) {
          return const ReminderPage(); // Redirect to add reminder page
        }

        return Scaffold(
          appBar: AppBar(title: const Text('My Reminders')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add New Reminder"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 14,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReminderPage()),
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: reminders.length,
                  itemBuilder:
                      (_, i) => _ReminderCard(
                        userId: userId,
                        reminder: reminders[i],
                        onRefresh: () => setState(() {}),
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onRefresh;
  final String userId;

  const _ReminderCard({
    required this.reminder,
    required this.onRefresh,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF5E5A2F);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEFD8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${reminder.date.day}',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(reminder.date).toUpperCase(),
                        style: TextStyle(fontSize: 15, color: color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          reminder.occasion,
                          style: TextStyle(fontSize: 12, color: color),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showReminderOptions(context),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF5E5A2F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {}, // Optional: add gift logic
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                ),
                child: const Text("Send Gifts"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReminderPage(reminder: reminder),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("Delete", style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context); // Close bottom sheet

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('reminders')
                    .doc(reminder.id)
                    .delete();

                if (context.mounted) {
                  onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reminder deleted')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
