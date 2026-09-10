import 'package:flutter/material.dart';

class PostCommentsScreen extends StatelessWidget {
  const PostCommentsScreen({super.key, required this.postId});
  final String postId;
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Kommentare')));
}
