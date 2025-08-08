import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BulkOrderPage extends StatefulWidget {
  const BulkOrderPage({super.key});

  @override
  State<BulkOrderPage> createState() => _DecorInfoPageState();
}

class _DecorInfoPageState extends State<BulkOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {};
  bool _isSubmitting = false;

  Future<void> _submitToFirebase() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final docId = _formData['mobile'];

      await FirebaseFirestore.instance
          .collection('callbackRequests')
          .doc(docId)
          .set({
            'name': _formData['name'],
            'mobile': _formData['mobile'],
            'occasion': _formData['occasion'],
            'preferredDate': _formData['date'],
            'location': _formData['location'],
            'message': _formData['message'],
            'submittedAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Callback request submitted successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          ''
          'Corporate Gifts/ Bulk Orders',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Request a Callback',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name*'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => _formData['name'] = value!,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number*',
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (value.length != 10)
                        return 'Enter valid 10-digit mobile number';
                      return null;
                    },
                    onSaved: (value) => _formData['mobile'] = value!,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Occasion* (e.g., Birthday, Wedding)',
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => _formData['occasion'] = value!,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Preferred Date*',
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => _formData['date'] = value!,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Location*'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                    onSaved: (value) => _formData['location'] = value!,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Additional Message',
                    ),
                    maxLines: 3,
                    onSaved: (value) => _formData['message'] = value ?? '',
                  ),
                  const SizedBox(height: 20),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isSubmitting
                              ? null
                              : () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  _submitToFirebase();
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit Request',
                                    style: TextStyle(color: Colors.white),
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
  }
}
