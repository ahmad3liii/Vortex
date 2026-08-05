import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vortex_market/logic/cubit/chat_cubit.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import 'package:vortex_market/presentation/widgets/background_widget.dart';

class ChatScreen extends StatefulWidget {
  final String sellerName;
  final String sellerId;

  const ChatScreen({
    super.key,
    required this.sellerName,
    required this.sellerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _chatId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final chatId = await context.read<ChatCubit>().getOrCreateChat(
      widget.sellerId,
    );
    if (chatId != null && mounted) {
      setState(() {
        _chatId = chatId;
        _isLoading = false;
      });
      context.read<ChatCubit>().fetchMessages(chatId);
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("فشل إنشاء المحادثة: معرف البائع غير صالح"),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    context.read<ChatCubit>().stopPolling();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _sendMessage() {
    if (_chatId == null) return;
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      context.read<ChatCubit>().sendMessage(_chatId!, text);
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _showBargainingDialog() {
    final offerController = TextEditingController();
    final isDark = context.read<ThemeCubit>().isDark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF1B1B2F)
            : Colors.grey.shade100,
        title: Text(
          "تقديم عرض سعر تفاوضي",
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "أدخل السعر الذي تود عرضه:",
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: offerController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "مثال: 75",
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "إلغاء",
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(offerController.text) ?? 0;
              if (amount > 0 && _chatId != null) {
                Navigator.pop(ctx);
                context.read<ChatCubit>().sendNegotiatedOffer(_chatId!, amount);
              }
            },
            child: const Text("إرسال العرض"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeCubit>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blueAccent.withOpacity(0.2),
              child: const Icon(
                Icons.person,
                color: Colors.blueAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.sellerName,
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: isDark
            ? const Color(0xFF0F0C29)
            : Colors.grey.shade200,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BackgroundWidget(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : BlocBuilder<ChatCubit, ChatState>(
                      builder: (context, state) {
                        final messages = state.messages;
                        if (state.isLoadingMessages && messages.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (messages.isEmpty) {
                          return Center(
                            child: Text(
                              "ابدأ المحادثة",
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          );
                        }
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                        );
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(15),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            return Align(
                              alignment: msg.isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: msg.isMe
                                      ? Colors.blueAccent
                                      : (isDark
                                            ? Colors.white.withOpacity(0.08)
                                            : Colors.black.withOpacity(0.05)),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(15),
                                    topRight: const Radius.circular(15),
                                    bottomLeft: Radius.circular(
                                      msg.isMe ? 15 : 0,
                                    ),
                                    bottomRight: Radius.circular(
                                      msg.isMe ? 0 : 15,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.text.isNotEmpty
                                          ? msg.text
                                          : '(رسالة فارغة)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        "${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}",
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            _buildMessageInput(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(15),
      color: isDark ? Colors.black26 : Colors.grey.shade300.withOpacity(0.3),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.handshake_rounded,
                color: Colors.blueAccent,
                size: 28,
              ),
              onPressed: _showBargainingDialog,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: "اكتب رسالتك هنا...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white10
                      : Colors.black.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
