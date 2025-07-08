// lib/screens/SupportChatPage.dart
import 'package:flutter/material.dart';

// تأكد من أن هذه الألوان معرفة ومتاحة، يفضل أن تكون في ملف ثوابت مشترك
const Color kPrimaryColor = Color(0xFF005B96);
const Color kAccentColor = Color(0xFFF7931E);
const Color kBackgroundColor = Color(0xFFFDFDFD);
const Color kSurfaceColor = Color(0xFFF5F5F5);
const Color kTextColor = Color(0xFF2D3436);
const Color kSecondaryTextColor = Color(0xFF757575);
const Color kDividerColor = Color(0xFFEAEAEA);
const Color kSuccessColor = Color(0xFF2ECC71);
const Color kErrorColor = Color(0xFFE74C3C);

class SupportChatPage extends StatefulWidget {
  const SupportChatPage({super.key});

  @override
  _SupportChatPageState createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"sender": "support", "text": "مرحبًا! كيف يمكننا مساعدتك اليوم؟"},
  ];
  final ScrollController _scrollController = ScrollController();

  void _sendMessage(String text) {
    if (text.trim().isNotEmpty) {
      setState(() {
        _messages.add({"sender": "user", "text": text.trim()});
        _messageController.clear();
      });

      // Scroll to the bottom to show the latest message
      _scrollController.animateTo(
        0.0, // Scroll to the start if reverse is true
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      // Add a dummy response from support after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _messages.add({"sender": "support", "text": "شكراً لرسالتك. سنقوم بمراجعتها والرد عليك في أقرب وقت ممكن!"});
          });
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدعم الفني'),
          centerTitle: true,
          backgroundColor: kPrimaryColor, // Use primary color for App Bar
          foregroundColor: Colors.white, // White text/icons
          elevation: 4, // Subtle elevation
        ),
        body: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 70, color: kSecondaryTextColor.withOpacity(0.5)),
                            const SizedBox(height: 20),
                            Text(
                              'ابدأ محادثة مع فريق الدعم الفني.',
                              style: textTheme.headlineSmall?.copyWith(color: kSecondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: true, // Show latest messages at the bottom
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index]; // Use index directly with reverse
                        final isUser = message["sender"] == "user";
                        return _buildMessageBubble(context, message["text"]!, isUser);
                      },
                    ),
            ),
            _buildMessageInput(context, textTheme),
          ],
        ),
      ),
    );
  }

  // --- Message Bubble Widget ---
  Widget _buildMessageBubble(BuildContext context, String text, bool isUser) {
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight, // RTL alignment for user on left, support on right
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), // Limit bubble width
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? kPrimaryColor : kSurfaceColor, // Primary for user, Surface for support
          borderRadius: BorderRadius.only(
            topLeft: isUser ? const Radius.circular(16) : const Radius.circular(16),
            topRight: isUser ? const Radius.circular(16) : const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(0) : const Radius.circular(16), // Pointed bottom-right for user
            bottomRight: isUser ? const Radius.circular(16) : const Radius.circular(0), // Pointed bottom-left for support
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: textTheme.bodyLarge?.copyWith(
            color: isUser ? Colors.white : kTextColor,
          ),
          textDirection: TextDirection.rtl, // Ensure RTL
        ),
      ),
    );
  }

  // --- Message Input Widget ---
  Widget _buildMessageInput(BuildContext context, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك هنا...',
                hintStyle: textTheme.bodyMedium?.copyWith(color: kSecondaryTextColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: kPrimaryColor, width: 1.5)),
                filled: true,
                fillColor: kSurfaceColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: null, // Allow multiple lines
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage, // Send message on enter
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: () {
                _sendMessage(_messageController.text);
              },
              tooltip: 'إرسال',
            ),
          ),
        ],
      ),
    );
  }
}