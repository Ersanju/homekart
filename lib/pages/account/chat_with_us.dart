import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatWithUs extends StatefulWidget {
  const ChatWithUs({super.key});

  @override
  State<ChatWithUs> createState() => _ChatWithUsState();
}

class _ChatWithUsState extends State<ChatWithUs> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
  final String _currentSessionId =
      DateTime.now().millisecondsSinceEpoch.toString();

  bool _showQuickReplies = false;
  bool _awaitingOrderId = false;
  bool _chatEnded = false;
  bool _isSessionEnded = false;
  bool _isArchiving = false;
  Timer? _inactivityTimer;
  bool _waitingForUserReply = false;
  bool _isSendingMessage = false;

  final List<String> _quickReplies = [
    "Order Status",
    "Cancel Order",
    "Talk to Support",
  ];

  @override
  void initState() {
    super.initState();
    _initializeChatOnce();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('timestamp');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Us"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (_isArchiving) return;

              if (value == 'end' && !_isSessionEnded) {
                setState(() {
                  _isArchiving = true;
                });
                await _endCurrentChat();
                setState(() {
                  _isSessionEnded = true;
                  _isArchiving = false;
                });
              } else if (value == 'new') {
                setState(() {
                  _isArchiving = true;
                });
                await _startNewChat();
                setState(() {
                  _isSessionEnded = false;
                  _isArchiving = false;
                });
              }
            },

            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'new',
                    child: Text('Start New Chat'),
                  ),
                  PopupMenuItem(
                    value: 'end',
                    enabled: !_isSessionEnded,
                    child: Text(
                      'End Chat',
                      style: TextStyle(
                        color: _isSessionEnded ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ],
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isNotEmpty) {
                  final latest = messages.last.data() as Map<String, dynamic>;
                  final sender = latest['sender'];

                  if (sender == 'bot' || sender == 'admin') {
                    if (!_waitingForUserReply) {
                      _startInactivityTimer(); // Start timer when admin/bot sends message
                    }
                  }

                  if (sender == 'user') {
                    _waitingForUserReply = false;
                    _inactivityTimer?.cancel();
                  }
                }

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  children:
                      messages
                          .map(
                            (doc) => _buildMessageBubble(
                              doc.data() as Map<String, dynamic>,
                            ),
                          )
                          .toList(),
                );
              },
            ),
          ),

          // Quick replies
          if (_showQuickReplies) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    _quickReplies
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _quickReplyButton(r),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],

          // Text input
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_chatEnded,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          _chatEnded
                              ? 'Chat has ended.'
                              : 'Type your message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) {
                      if (!_chatEnded) {
                        _sendMessage(message: _messageController.text);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed:
                      _chatEnded || _isSendingMessage
                          ? null
                          : () =>
                              _sendMessage(message: _messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeChatOnce() async {
    final sessionCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chatSessions');

    final lastSession =
        await sessionCollection
            .orderBy('endedAt', descending: true)
            .limit(1)
            .get();

    final wasEnded =
        lastSession.docs.isNotEmpty &&
        (lastSession.docs.first.data()['isEnded'] == true);

    final chatSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('chats')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

    if (wasEnded || chatSnapshot.docs.isEmpty) {
      await deleteAllMessages(userId);
      await _sendInitialMessages();
    }
  }

  Future<void> _sendMessage({required String message}) async {
    if (message.trim().isEmpty || _isSendingMessage) return;

    setState(() {
      _isSendingMessage = true;
    });

    final trimmedMsg = message.trim();

    _inactivityTimer?.cancel();
    _waitingForUserReply = false;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats')
        .add({
          'sender': 'user',
          'message': trimmedMsg,
          'timestamp': FieldValue.serverTimestamp(),
        });

    _messageController.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();

    // Bot logic
    if (_awaitingOrderId) {
      _awaitingOrderId = false;
      await Future.delayed(const Duration(milliseconds: 100));
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('chats')
          .add({
            'sender': 'bot',
            'message':
                "Thanks for sharing your order ID. Our team will reach out to you shortly.",
            'timestamp': FieldValue.serverTimestamp(),
          });
    }

    setState(() {
      _isSendingMessage = false;
    });
  }

  void _startInactivityTimer() {
    _waitingForUserReply = true;
    _inactivityTimer?.cancel();

    // After 10 seconds of inactivity, show the "Are you still there?" dialog
    _inactivityTimer = Timer(const Duration(seconds: 120), () async {
      if (!mounted || _chatEnded) return;

      bool userResponded = false;

      // Show dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          // Auto-close dialog after 10 seconds and check user response
          Future.delayed(const Duration(seconds: 60), () async {
            if (!userResponded && Navigator.canPop(ctx)) {
              Navigator.of(ctx).pop(); // Close dialog
              if (_waitingForUserReply && !_chatEnded) {
                await _endCurrentChat(); // End chat if no response
              }
            }
          });

          return AlertDialog(
            title: const Text('Are you still there and need assistance?'),
            actions: [
              TextButton(
                onPressed: () {
                  userResponded = true;
                  Navigator.of(ctx).pop();
                  _waitingForUserReply = false;
                  _startInactivityTimer(); // Restart timer after response
                },
                child: const Text('Yes, I am here'),
              ),
            ],
          );
        },
      );
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendInitialMessages() async {
    final chatCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats');

    final snapshot = await chatCollection.limit(1).get();

    if (snapshot.docs.isEmpty) {
      // Animate message 1
      await Future.delayed(const Duration(milliseconds: 0));
      await chatCollection.add({
        'sender': 'bot',
        'message':
            'Hello!\n\nWelcome to Joy-a-Bloom, your personalized celebration partner 🌸🎉',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Animate message 2
      await Future.delayed(const Duration(milliseconds: 50));
      await chatCollection.add({
        'sender': 'bot',
        'message':
            "I'm Bloomy, your gifting assistant. How may I help you today?",
        'timestamp': FieldValue.serverTimestamp(),
      });

      await Future.delayed(const Duration(milliseconds: 50));
      setState(() => _showQuickReplies = true);
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> data) {
    final isUser = data['sender'] == 'user';
    final message = data['message'] ?? '';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final time =
        timestamp != null
            ? TimeOfDay.fromDateTime(timestamp).format(context)
            : '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.grey.shade300 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(message, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickReplyButton(String text) {
    return GestureDetector(
      onTap: () async {
        setState(() => _showQuickReplies = false);
        await _sendMessage(message: text); // Now shows in chat

        // Bot auto-response
        Future.delayed(const Duration(milliseconds: 100), () async {
          String botReply = '';
          if (text.toLowerCase().contains("support")) {
            botReply = "Our team will join you shortly.";
          } else if (text.toLowerCase().contains("order status")) {
            botReply = "Please enter your order ID.";
            _awaitingOrderId = true;
          } else if (text.toLowerCase().contains("cancel")) {
            botReply =
                "Please confirm your order ID to proceed with cancellation.";
            _awaitingOrderId = true;
          }

          if (botReply.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('chats')
                .add({
                  'sender': 'bot',
                  'message': botReply,
                  'timestamp': FieldValue.serverTimestamp(),
                });
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _startNewChat() async {
    final chatCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats');

    if (!_chatEnded) {
      await _saveCurrentChatToArchive();
    }

    // Reset flags and start fresh
    setState(() {
      _showQuickReplies = false;
      _awaitingOrderId = false;
      _chatEnded = false;
      _isSessionEnded = false;
    });
    await deleteAllMessages(userId);
    // Add fresh bot messages
    await Future.delayed(const Duration(milliseconds: 100));
    await chatCollection.add({
      'sender': 'bot',
      'message': 'Hi again! 👋 Let\'s start fresh!',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await Future.delayed(const Duration(seconds: 1));
    await chatCollection.add({
      'sender': 'bot',
      'message': "How may I assist you today?",
      'timestamp': FieldValue.serverTimestamp(),
    });

    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _showQuickReplies = true;
    });
  }

  Future<void> deleteAllMessages(String userId) async {
    final chatCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats');

    const int batchSize = 500;
    QuerySnapshot snapshot = await chatCollection.limit(batchSize).get();

    while (snapshot.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      snapshot = await chatCollection.limit(batchSize).get();
    }
  }

  Future<void> _saveCurrentChatToArchive() async {
    final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final chatCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats');
    final newSessionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chatSessions')
        .doc(newSessionId);

    final messages = await chatCollection.orderBy('timestamp').get();

    // ✅ Only archive if more than 10 messages
    if (messages.docs.length > 10) {
      final batch = FirebaseFirestore.instance.batch();
      for (var msg in messages.docs) {
        final msgRef = newSessionRef.collection('messages').doc();
        batch.set(msgRef, msg.data());
      }

      batch.set(newSessionRef, {
        'endedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    }
  }

  Future<void> _endCurrentChat() async {
    if (_isSessionEnded) return;

    final sessionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chatSessions')
        .doc(_currentSessionId);

    final chatCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats');

    final messages = await chatCollection.orderBy('timestamp').get();

    // ✅ Only save session if more than 10 messages
    if (messages.docs.length > 10) {
      final batch = FirebaseFirestore.instance.batch();

      for (var msg in messages.docs) {
        final msgRef = sessionRef.collection('messages').doc();
        batch.set(msgRef, msg.data());
      }

      batch.set(sessionRef, {
        'endedAt': FieldValue.serverTimestamp(),
        'isEnded': true,
      }, SetOptions(merge: true));

      await batch.commit();
    }

    // Always show final message even if not saved
    await chatCollection.add({
      'sender': 'bot',
      'message': 'Thank you for chatting with us! 😊',
      'timestamp': FieldValue.serverTimestamp(),
    });

    setState(() {
      _showQuickReplies = false;
      _awaitingOrderId = false;
      _chatEnded = true;
      _isSessionEnded = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Chat ended.")));
  }
}
