import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Group id ('blau' | 'gelb' | 'rot') → accent color / initial, matching
/// the prototype's hardcoded G constants.
Color groupColor(String? groupId) => switch (groupId) {
      'blau' => AppColors.groupBlau,
      'gelb' => AppColors.groupGelb,
      'rot' => AppColors.groupRot,
      _ => AppColors.neutral600,
    };

String groupInitial(String? groupId) => switch (groupId) {
      'blau' => 'B',
      'gelb' => 'G',
      'rot' => 'R',
      _ => '?',
    };

String groupName(String? groupId) => switch (groupId) {
      'blau' => 'Blau',
      'gelb' => 'Gelb',
      'rot' => 'Rot',
      _ => 'Alle',
    };
