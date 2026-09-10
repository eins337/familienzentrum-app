import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({super.key, required this.chatId});
  final String chatId;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Chat $chatId')));
}
