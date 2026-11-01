import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';

class SvLoading extends StatelessWidget {
  const SvLoading({super.key, this.label = 'Loading SmartVital data'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label,
        liveRegion: true,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
