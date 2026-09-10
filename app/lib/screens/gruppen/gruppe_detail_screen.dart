import 'package:flutter/material.dart';

class GruppeDetailScreen extends StatelessWidget {
  const GruppeDetailScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Gruppe $groupId')));
}
