import 'package:flutter/material.dart';

class KrankmeldenSheet extends StatelessWidget {
  const KrankmeldenSheet({super.key, required this.childId});
  final String childId;
  @override
  Widget build(BuildContext context) => const SizedBox(height: 200, child: Center(child: Text('Krankmelden')));
}
