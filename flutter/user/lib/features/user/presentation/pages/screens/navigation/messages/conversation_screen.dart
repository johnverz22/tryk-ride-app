import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

class ConversationScreen extends StatefulWidget {
  final String name;

  const ConversationScreen({super.key, required this.name});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<Message> _messages = [];
  bool _hasText = false;
  bool _showIcons = true;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _hasText = _messageController.text.trim().isNotEmpty;
      });
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _messageController.clear();
    });

    _scrollToBottom();
    _focusNode.requestFocus();

    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        _messages.add(Message(text: _generateDriverReply(text), isUser: false));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _generateDriverReply(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains("where")) {
      return "I'm just around the corner!";
    } else if (lower.contains("how long")) {
      return "Roughly 2 minutes away.";
    } else {
      return "Got it!";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (isKeyboardVisible && _showIcons) {
      _showIcons = false;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: color.primary,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: color.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.name,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {},
            tooltip: 'Call',
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
            tooltip: 'Video Call',
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Driver Info"),
                  content: const Text("This is the driver's chat screen."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Info',
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                final isUser = msg.isUser;

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? color.primary : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isUser ? 14 : 2),
                        bottomRight: Radius.circular(isUser ? 2 : 14),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      if (_showIcons) ...[
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.image_outlined),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic_none),
                          onPressed: () {},
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.arrow_right),
                          onPressed: () {
                            setState(() {
                              _showIcons = true;
                            });
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ],
                      Expanded(
                        child: TextField(
                          focusNode: _focusNode,
                          controller: _messageController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          onTap: () {
                            if (_showEmojiPicker) {
                              setState(() {
                                _showEmojiPicker = false;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.emoji_emotions_outlined),
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _showEmojiPicker = !_showEmojiPicker;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _hasText
                          ? Container(
                              decoration: BoxDecoration(
                                color: color.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                                onPressed: _sendMessage,
                              ),
                            )
                          : IconButton(
                              icon: const Text(
                                "😊",
                                style: TextStyle(fontSize: 24),
                              ),
                              tooltip: "Send smile emoji",
                              onPressed: () {
                                setState(() {
                                  _messages.add(
                                    Message(text: "😊", isUser: true),
                                  );
                                });
                                _scrollToBottom();
                                _focusNode.requestFocus();
                                Future.delayed(
                                  const Duration(milliseconds: 700),
                                  () {
                                    setState(() {
                                      _messages.add(
                                        Message(
                                          text: _generateDriverReply("😊"),
                                          isUser: false,
                                        ),
                                      );
                                    });
                                    _scrollToBottom();
                                  },
                                );
                              },
                              onLongPress: () {
                                debugPrint("Long press detected.");
                              },
                            ),
                    ],
                  ),
                ),
                if (_showEmojiPicker)
                  SizedBox(
                    height: 300,
                    child: EmojiPicker(
                      onEmojiSelected: (Category? category, Emoji emoji) {
                        _messageController
                          ..text += emoji.emoji
                          ..selection = TextSelection.fromPosition(
                            TextPosition(
                              offset: _messageController.text.length,
                            ),
                          );
                      },
                      onBackspacePressed: () {
                        final text = _messageController.text;
                        if (text.isNotEmpty) {
                          _messageController.text = text.characters
                              .skipLast(1)
                              .toString();
                          _messageController.selection =
                              TextSelection.fromPosition(
                                TextPosition(
                                  offset: _messageController.text.length,
                                ),
                              );
                        }
                      },
                      textEditingController: _messageController,
                      config: Config(
                        height: 300,
                        checkPlatformCompatibility: false,
                        emojiViewConfig: EmojiViewConfig(
                          emojiSizeMax: 32.0,
                          verticalSpacing: 4,
                          horizontalSpacing: 4,
                          columns: 8,
                          recentsLimit: 30,
                          noRecents: Text(
                            'No Recents',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black26,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        categoryViewConfig: CategoryViewConfig(
                          backgroundColor: Colors.grey[200]!,
                          iconColor: Colors.grey,
                          iconColorSelected: Colors.blueAccent,
                          backspaceColor: Colors.redAccent,
                          indicatorColor: Colors.blueAccent,
                          recentTabBehavior: RecentTabBehavior.RECENT,
                          // extraTab: CategoryExtraTab.BACKSPACE,
                        ),
                        skinToneConfig: SkinToneConfig(
                          indicatorColor: Colors.grey,
                          dialogBackgroundColor: Colors.white,
                        ),
                        bottomActionBarConfig: BottomActionBarConfig(
                          showBackspaceButton: true,
                          showSearchViewButton: true,
                          backgroundColor: Colors.blueAccent,
                          buttonIconColor: Colors.white,
                        ),
                        searchViewConfig: SearchViewConfig(
                          backgroundColor: Colors.grey[100]!,
                          hintText: 'Search emojis...',
                          buttonIconColor: Colors.black26,
                        ),
                        viewOrderConfig: const ViewOrderConfig(
                          top: EmojiPickerItem.categoryBar,
                          middle: EmojiPickerItem.emojiView,
                          bottom: EmojiPickerItem.searchBar,
                        ),
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
