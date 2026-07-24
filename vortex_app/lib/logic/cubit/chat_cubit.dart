import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vortex_market/data/models/app_models.dart';
import 'package:vortex_market/logic/services/api_service.dart';

class ChatState {
  final List<ChatModel> chats;
  final List<MessageModel> messages;
  final bool isLoadingChats;
  final bool isLoadingMessages;
  final String? errorMessage;
  final int? activeChatId;

  ChatState({
    this.chats = const [],
    this.messages = const [],
    this.isLoadingChats = false,
    this.isLoadingMessages = false,
    this.errorMessage,
    this.activeChatId,
  });

  ChatState copyWith({
    List<ChatModel>? chats,
    List<MessageModel>? messages,
    bool? isLoadingChats,
    bool? isLoadingMessages,
    String? errorMessage,
    int? activeChatId,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      messages: messages ?? this.messages,
      isLoadingChats: isLoadingChats ?? this.isLoadingChats,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      errorMessage: errorMessage,
      activeChatId: activeChatId ?? this.activeChatId,
    );
  }
}

class ChatCubit extends Cubit<ChatState> {
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;

  ChatCubit() : super(ChatState());

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // ✅ FIX: Safe parsing for sellerId (Issue 2)
  int? _parseUserId(String idString) {
    if (idString.isEmpty) return null;

    // Try direct parsing first
    int? parsed = int.tryParse(idString);
    if (parsed != null) return parsed;

    // Try to extract numeric part from formatted strings like "s1", "user_1", "id123"
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(idString);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }

    return null;
  }

  Future<void> fetchChats() async {
    emit(state.copyWith(isLoadingChats: true, errorMessage: null));
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        emit(
          state.copyWith(
            isLoadingChats: false,
            errorMessage: "يجب تسجيل الدخول",
          ),
        );
        return;
      }
      final response = await _apiService.getActiveChats(userId);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['chats'] ?? []);
        final chats = data.map((json) => ChatModel.fromMap(json)).toList();
        emit(state.copyWith(chats: chats, isLoadingChats: false));
      } else {
        emit(state.copyWith(isLoadingChats: false));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingChats: false,
          errorMessage: "تعذر تحميل المحادثات",
        ),
      );
    }
  }

  // ✅ FIX: Updated to handle String sellerId with safe parsing (Issue 2)
  Future<int?> getOrCreateChat(String otherUserId) async {
    final currentUserId = await getCurrentUserId();
    if (currentUserId == null) return null;

    // ✅ Safe parse the sellerId
    int? otherUserIdInt = _parseUserId(otherUserId);
    if (otherUserIdInt == null) {
      print('❌ Could not parse sellerId: $otherUserId');
      return null;
    }

    if (state.chats.isEmpty) {
      await fetchChats();
    }

    ChatModel? existingChat;
    for (var chat in state.chats) {
      if (chat.otherUserId == otherUserId ||
          _parseUserId(chat.otherUserId) == otherUserIdInt) {
        existingChat = chat;
        break;
      }
    }

    if (existingChat != null) {
      return int.tryParse(existingChat.id);
    }

    try {
      final response = await _apiService.startChat(
        sender_id: currentUserId,
        receiver_id: otherUserIdInt,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final chatId =
            response.data['chat_id'] ??
            response.data['id'] ??
            response.data['chatId'];
        if (chatId == null) return null;
        await fetchChats();
        return int.tryParse(chatId.toString());
      } else {
        print('❌ Failed to start chat: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error starting chat: $e');
      return null;
    }
  }

  Future<void> fetchMessages(int chatId) async {
    _pollingTimer?.cancel();
    emit(
      state.copyWith(
        isLoadingMessages: true,
        activeChatId: chatId,
        errorMessage: null,
      ),
    );
    try {
      final response = await _apiService.getMessageHistory(chatId);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['messages'] ?? []);
        final messages = data
            .map((json) => MessageModel.fromMap(json))
            .toList();
        print('📨 Fetched ${messages.length} messages');
        emit(state.copyWith(messages: messages, isLoadingMessages: false));
      } else {
        emit(state.copyWith(isLoadingMessages: false));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMessages: false,
          errorMessage: "تعذر تحميل الرسائل",
        ),
      );
    }

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (state.activeChatId == chatId) {
        try {
          final response = await _apiService.getMessageHistory(chatId);
          if (response.statusCode == 200) {
            final List<dynamic> data = response.data is List
                ? response.data
                : (response.data['messages'] ?? []);
            final newMessages = data
                .map((json) => MessageModel.fromMap(json))
                .toList();
            if (newMessages.length != state.messages.length) {
              emit(state.copyWith(messages: newMessages));
            }
          }
        } catch (_) {}
      } else {
        timer.cancel();
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    emit(state.copyWith(activeChatId: null));
  }

  Future<void> sendMessage(int chatId, String text) async {
    if (text.trim().isEmpty) return;
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;
      final response = await _apiService.sendMessage(
        chat_id: chatId,
        sender_id: userId,
        content: text,
      );
      if (response.statusCode == 201) {
        await fetchMessages(chatId);
        fetchChats();
      }
    } catch (_) {}
  }

  Future<void> sendNegotiatedOffer(int chatId, double amount) async {
    await sendMessage(chatId, "OFFER_PRICE:$amount");
  }

  Future<void> respondToOffer(
    int chatId,
    String messageId,
    String status,
  ) async {
    await sendMessage(chatId, "OFFER_RESPONSE:$messageId:$status");
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
