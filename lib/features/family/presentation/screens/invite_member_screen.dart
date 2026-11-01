import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/sv_button.dart';

class InviteMemberScreen extends ConsumerStatefulWidget {
  const InviteMemberScreen({super.key});

  @override
  ConsumerState<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends ConsumerState<InviteMemberScreen> {
  String? _selectedRelationship;
  final _emailController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendEmailInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }
    if (_selectedRelationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a relationship')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(apiClientProvider).postMap(
        '/family/invite',
        data: {
          'email': email,
          'relationship': _selectedRelationship!.toLowerCase(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite sent to $email'),
          backgroundColor: AppColors.success,
        ),
      );
      _emailController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send invite: ${e.toString()}'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect with a family member')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Relationship', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: [
              'Spouse', 'Parent', 'Child', 'Sibling', 'Grandparent', 'Other'
            ].map((r) => ChoiceChip(
              label: Text(r),
              selected: _selectedRelationship == r,
              onSelected: (selected) =>
                  setState(() => _selectedRelationship = selected ? r : null),
            )).toList(),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to QR screen which generates a real token
                    // and allows sharing via link OR QR
                    context.go('/home/family/qr');
                  },
                  child: const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.qr_code),
                          SizedBox(height: 8),
                          Text('QR Code'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  // "Share Link" also goes to the QR screen —
                  // that screen has a dedicated Share button with
                  // the real token-embedded deep link.
                  onTap: () => context.go('/home/family/qr'),
                  child: const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(Icons.link),
                          SizedBox(height: 8),
                          Text('Share Link'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Or send via email:'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email address'),
                ),
              ),
              const SizedBox(width: 8),
              SvButton(
                label: 'Send',
                fullWidth: false,
                isLoading: _sending,
                onPressed: _sendEmailInvite,
              ),
            ],
          ),
          const SizedBox(height: 32),
          ListTile(
            title: const Text('Customize what they can see'),
            trailing: const Icon(Icons.expand_more),
            onTap: () => context.go('/home/family/share-settings'),
          ),
        ],
      ),
    );
  }
}
