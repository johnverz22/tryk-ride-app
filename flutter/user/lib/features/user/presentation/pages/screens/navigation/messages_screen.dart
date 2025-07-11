import 'package:flutter/material.dart';
import 'package:user/features/user/presentation/pages/screens/navigation/messages/conversation_screen.dart';
import 'package:user/features/user/presentation/widgets/appbar/app_bar.dart';

// Sample message model (replace with your real model)
class MessageThread {
  final String name;
  final String message;
  final String time;

  MessageThread(this.name, this.message, this.time);
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<MessageThread> _allMessages = [
    MessageThread(
      'Driver Mike',
      'Your ride is arriving in 2 minutes.',
      '4:32 PM',
    ),
    MessageThread('Driver Sarah', 'I have reached your location.', '3:20 PM'),
    MessageThread('Support', 'We’ve received your complaint.', 'Yesterday'),
    MessageThread('Driver John', 'Thanks for the ride!', 'Monday'),
    // Add more mock messages here...
  ];

  List<MessageThread> _filteredMessages = [];

  @override
  void initState() {
    super.initState();
    _filteredMessages = _allMessages;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMessages = _allMessages.where((msg) {
        return msg.name.toLowerCase().contains(query) ||
            msg.message.toLowerCase().contains(query);
      }).toList();
    });
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
            child: _filteredMessages.isEmpty
                ? Center(
                    child: Text(
                      'No messages found.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
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
                              builder: (_) =>
                                  ConversationScreen(name: msg.name),
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
                          msg.time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
