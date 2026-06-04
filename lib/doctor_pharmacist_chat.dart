import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class ChatMessage {
  final String sender;
  final String senderName;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.sender,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'sender': sender,
    'senderName': senderName,
    'text': text,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    sender: j['sender'] as String,
    senderName: j['senderName'] as String,
    text: j['text'] as String,
    timestamp: DateTime.fromMillisecondsSinceEpoch(j['timestamp'] as int),
  );
}

class DoctorPharmacistChat extends StatefulWidget {
  final String firstName;
  final String userRole;

  const DoctorPharmacistChat({
    required this.firstName,
    required this.userRole,
    super.key,
  });

  @override
  State<DoctorPharmacistChat> createState() => _DoctorPharmacistChatState();
}

class _DoctorPharmacistChatState extends State<DoctorPharmacistChat> {
  final _db = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  CollectionReference<Map<String, dynamic>> get _messagesCol =>
      _db.collection('chat_doc_pharm').doc('thread').collection('messages');

  Stream<List<ChatMessage>> get _chatStream => _messagesCol
      .orderBy('timestamp')
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => ChatMessage.fromJson(d.data())).toList(),
      );

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _messagesCol.add(
      ChatMessage(
        sender: widget.userRole,
        senderName: widget.firstName,
        text: text,
        timestamp: DateTime.now(),
      ).toJson(),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final otherRole = widget.userRole == 'doctor' ? 'Pharmacist' : 'Doctor';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
            decoration: const BoxDecoration(
              color: kCardBg,
              border: Border(bottom: BorderSide(color: kBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: kGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.userRole == 'doctor'
                        ? Icons.local_pharmacy_outlined
                        : Icons.medical_services_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat with $otherRole',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                        ),
                      ),
                      const Text(
                        'Secure professional channel',
                        style: TextStyle(fontSize: 11, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Messages (real-time stream)
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  );
                }
                final messages = snapshot.data ?? [];
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.sender == widget.userRole;
                    final showTime =
                        i == 0 ||
                        msg.timestamp
                                .difference(messages[i - 1].timestamp)
                                .inMinutes >
                            30;

                    return Column(
                      children: [
                        if (showTime)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _formatTime(msg.timestamp),
                              style: const TextStyle(
                                fontSize: 11,
                                color: kTextSecondary,
                              ),
                            ),
                          ),
                        Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: 6,
                              left: isMe ? 56 : 0,
                              right: isMe ? 0 : 56,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? kPrimary : kCardBg,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                              border: isMe ? null : Border.all(color: kBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.senderName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : kTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  msg.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isMe ? Colors.white : kTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              10 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: kCardBg,
              border: Border(top: BorderSide(color: kBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: kGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
