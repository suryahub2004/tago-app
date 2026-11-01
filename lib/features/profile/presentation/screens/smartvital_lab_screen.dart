import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SmartvitalLabScreen extends StatefulWidget {
  const SmartvitalLabScreen({super.key});

  @override
  State<SmartvitalLabScreen> createState() => _SmartvitalLabScreenState();
}

class _SmartvitalLabScreenState extends State<SmartvitalLabScreen> {
  bool _betaFirmware = false;
  bool _advancedSleep = true;
  bool _aiInsights = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SmartVital Lab'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.science, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Experimental Features',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try out new features before they are released to everyone. These features may be unstable.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 48),
          _buildLabToggle(
            'Beta Firmware Updates',
            'Receive early access to ring firmware updates.',
            _betaFirmware,
            (val) => setState(() => _betaFirmware = val),
          ),
          const SizedBox(height: 16),
          _buildLabToggle(
            'Advanced Sleep Stages (Beta)',
            'Use our new AI model to detect REM and Deep sleep more accurately.',
            _advancedSleep,
            (val) => setState(() => _advancedSleep = val),
          ),
          const SizedBox(height: 16),
          _buildLabToggle(
            'Generative AI Insights',
            'Let our LLM analyze your vitals and give you daily personalized tips.',
            _aiInsights,
            (val) => setState(() => _aiInsights = val),
          ),
        ],
      ),
    );
  }

  Widget _buildLabToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
