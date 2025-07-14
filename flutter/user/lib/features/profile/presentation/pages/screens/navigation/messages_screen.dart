import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:user/features/profile/presentation/pages/screens/navigation/messages/conversation_screen.dart';
import 'package:user/features/profile/presentation/widgets/appbar/app_bar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MessageThread {
  final int conversationId;
  final String name;
  final String message;
  final DateTime createdAt;

  MessageThread({
    required this.conversationId,
    required this.name,
    required this.message,
    required this.createdAt,
  });

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    return MessageThread(
      conversationId: json['conversation_id'],
      name: json['sender']['name'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (msgDate == today) {
      return '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (today.difference(msgDate).inDays == 1) {
      return 'Yesterday';
    } else {
      return '${createdAt.month}/${createdAt.day}';
    }
  }
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final storage = const FlutterSecureStorage();
  String? baseUrl = dotenv.env['BASE_URL'];

  List<MessageThread> _allMessages = [];
  List<MessageThread> _filteredMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadMessages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMessages =
          _allMessages
              .where(
                (msg) =>
                    msg.name.toLowerCase().contains(query) ||
                    msg.message.toLowerCase().contains(query),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final token = await storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/conversations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List jsonData = json.decode(response.body);
        final messages = jsonData.map((e) => MessageThread.fromJson(e)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          _allMessages = messages;
          _filteredMessages = List.from(messages);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      appBar: CustomUserAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMessages.isEmpty
                ? Center(
                    child: Text(
                      'No messages found.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredMessages.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (context, index) {
                        final msg = _filteredMessages[index];
                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ConversationScreen(
                                  conversationId: msg.conversationId,
                                  name: msg.name,
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: color.primary.withOpacity(0.1),
                            child: Icon(Icons.person, color: color.primary),
                          ),
                          title: Text(
                            msg.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            msg.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                          trailing: Text(
                            msg.formattedTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
