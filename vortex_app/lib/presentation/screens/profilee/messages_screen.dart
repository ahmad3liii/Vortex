import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vortex_market/logic/cubit/chat_cubit.dart';
import 'package:vortex_market/presentation/screens/chat/chat_screen.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/logic/cubit/theme_cubit.dart';
import 'package:vortex_market/l10n/app_localizations.dart';
import 'package:vortex_market/presentation/widgets/background_widget.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().fetchChats();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.watch<ThemeCubit>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.translate('messages') ?? "الرسائل",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? Colors.transparent : Colors.grey.shade200,
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
        child: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            if (state.isLoadingChats) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            final list = state.chats;

            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 70,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      l10n?.translate('no_active_chats') ??
                          "لا توجد محادثات نشطة حالياً.",
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final chat = list[index];
                return _buildChatTile(chat, isDark);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatTile(ChatModel chat, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(chat.otherUserAvatar),
          backgroundColor: isDark
              ? Colors.white10
              : Colors.black.withOpacity(0.05),
          onBackgroundImageError: (_, __) {},
        ),
        title: Text(
          chat.otherUserName,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            chat.lastMessage,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${chat.lastMessageTime.hour}:${chat.lastMessageTime.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 11,
              ),
            ),
            if (chat.unreadCount > 0) ...[
              const SizedBox(height: 5),
              CircleAvatar(
                radius: 9,
                backgroundColor: Colors.redAccent,
                child: Text(
                  "${chat.unreadCount}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                sellerName: chat.otherUserName,
                sellerId: chat.otherUserId,
              ),
            ),
          ).then((_) {
            context.read<ChatCubit>().fetchChats();
          });
        },
      ),
    );
  }
}
