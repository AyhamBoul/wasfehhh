import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ChatMessage {
  final String sender; // 'doctor' or 'pharmacist'
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
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(j['timestamp'] as int),
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
  static const _key = 'qm_chat_messages';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    List<ChatMessage> loaded = [];
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      loaded = list
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (loaded.isEmpty) {
      loaded = [
        ChatMessage(
          sender: 'pharmacist',
          senderName: 'Pharmacist',
          text: 'Hello! Any questions about medications or stock?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        ChatMessage(
          sender: 'doctor',
          senderName: 'Doctor',
          text: 'Hi! I need to check availability of Amoxicillin 500mg.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        ChatMessage(
          sender: 'pharmacist',
          senderName: 'Pharmacist',
          text: 'We have sufficient stock. How many units do you need?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        ),
      ];
      await _saveMessages(loaded);
    }
    if (mounted) {
      setState(() {
        _messages = loaded;
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveMessages(List<ChatMessage> msgs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(msgs.map((m) => m.toJson()).toList()));
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final msg = ChatMessage(
      sender: widget.userRole,
      senderName: widget.userRole == 'doctor' ? 'Doctor' : 'Pharmacist',
      text: text,
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(msg));
    _controller.clear();
    _saveMessages(_messages);
    _scrollToBottom();
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
    final otherRole =
        widget.userRole == 'doctor' ? 'Pharmacist' : 'Doctor';

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
          // Handle bar
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
                            color: kTextPrimary),
                      ),
                      const Text(
                        'Secure professional channel',
                        style:
                            TextStyle(fontSize: 11, color: kTextSecondary),
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

          // Messages
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: kPrimary))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = msg.sender == widget.userRole;
                      final showTime = i == 0 ||
                          msg.timestamp
                                  .difference(_messages[i - 1].timestamp)
                                  .inMinutes >
                              30;

                      return Column(
                        children: [
                          if (showTime)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _formatTime(msg.timestamp),
                                style: const TextStyle(
                                    fontSize: 11, color: kTextSecondary),
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
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? kPrimary : kCardBg,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft:
                                      Radius.circular(isMe ? 16 : 4),
                                  bottomRight:
                                      Radius.circular(isMe ? 4 : 16),
                                ),
                                border: isMe
                                    ? null
                                    : Border.all(color: kBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.04),
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
                                          ? Colors.white
                                              .withValues(alpha: 0.7)
                                          : kTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isMe
                                          ? Colors.white
                                          : kTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                10 + MediaQuery.of(context).viewInsets.bottom),
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
                          horizontal: 16, vertical: 10),
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
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
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
