import 'package:flutter/material.dart';
import 'package:fyp_source_code/chat/presentation/provider/chat_provider.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_colors.dart';
import 'package:fyp_source_code/utilities/reuse_components/app_text.dart';
import 'package:fyp_source_code/utilities/reuse_components/spacing.dart';
import 'package:fyp_source_code/utilities/reuse_widgets/app_bar.dart';
import 'package:get/get.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatProvider chatProvider;
  Worker? _messagesWorker;

  @override
  void initState() {
    super.initState();
    chatProvider =
        Get.isRegistered<ChatProvider>()
            ? Get.find<ChatProvider>()
            : Get.put(ChatProvider());

    // Load conversation
    chatProvider.openConversation(widget.receiverId);

    // Auto-scroll on new messages
    _messagesWorker = ever(chatProvider.currentMessages, (_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messagesWorker?.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  String? _currentUserId() => chatProvider.currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: WeHelpAppBar(
        title: widget.receiverName,
        showBack: true,
        subtitleWidget: Obx(() {
          final _ = chatProvider.typingUsers.length;
          final isTyping = chatProvider.typingUsers[widget.receiverId] == true;
          return Text(
            isTyping ? 'chat.typing'.tr : 'chat.direct_conversation'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyling.body_12S.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          );
        }),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat list
            Expanded(
              child: Obx(() {
                final messages = chatProvider.currentMessages;
                print('🔍 [UI] Messages count: ${messages.length}');

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'chat.no_messages'.tr,
                      style: AppTextStyling.body_14M.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(AppSize.mH),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final userId = _currentUserId();
                    final isMe = userId != null && msg.senderId == userId;
                    return ChatMessageBubble(msg: msg, isMe: isMe);
                  },
                );
              }),
            ),

            // Input Field
            SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSize.m,
                  vertical: AppSize.s,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        onChanged: (txt) {
                          chatProvider.onTyping(
                            receiverId: widget.receiverId,
                            isTyping: txt.isNotEmpty,
                          );
                        },
                        decoration: InputDecoration(
                          hintText: 'chat.message_hint'.tr,
                          hintStyle: AppTextStyling.body_12S.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSize.m,
                            vertical: AppSize.s,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.lightBorderGray,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.steelBlue,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              theme.inputDecorationTheme.fillColor ??
                              scheme.surface,
                        ),
                        style: AppTextStyling.body_12S.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSize.s),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.steelBlue,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send),
                        color: AppColors.pureWhite,
                        onPressed: () {
                          final txt = _msgController.text.trim();
                          if (txt.isNotEmpty) {
                            print('📤 Sending: $txt to ${widget.receiverId}');
                            chatProvider.sendMessage(
                              receiverId: widget.receiverId,
                              content: txt,
                            );
                            _msgController.clear();
                            chatProvider.onTyping(
                              receiverId: widget.receiverId,
                              isTyping: false,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Professional message bubble widget
class ChatMessageBubble extends StatelessWidget {
  final dynamic msg;
  final bool isMe;

  const ChatMessageBubble({super.key, required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final receivedBubbleColor =
        Theme.of(context).brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : AppColors.background;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: AppSize.s,
          horizontal: AppSize.xsH,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.l,
          vertical: AppSize.m,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.safetyBlue : receivedBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMe ? 20 : 4),
            topRight: Radius.circular(isMe ? 4 : 20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: (isMe ? AppColors.safetyBlue : AppColors.steelBlue)
                  .withValues(alpha: 0.15),
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
          border:
              !isMe
                  ? Border.all(color: AppColors.lightBorderGray, width: 1)
                  : null,
        ),
        child: Text(
          msg.content,
          maxLines: 10,
          style: AppTextStyling.body_14M.copyWith(
            color: isMe ? AppColors.pureWhite : scheme.onSurface,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
