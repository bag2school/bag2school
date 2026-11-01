import 'package:flutter/material.dart';

import 'services/bagi_identity_controller.dart';

class BagiIdentitySettingsPage extends StatefulWidget {
  const BagiIdentitySettingsPage({super.key});

  @override
  State<BagiIdentitySettingsPage> createState() =>
      _BagiIdentitySettingsPageState();
}

class _BagiIdentitySettingsPageState extends State<BagiIdentitySettingsPage> {
  static const Color _orange = Color(0xFFFF7A21);

  String? _gender;
  String? _preferredTitle;
  bool _saving = false;

  final TextEditingController _preferredNameController =
      TextEditingController();

  static const List<String> _genderOptions = <String>[
    'male',
    'female',
    'prefer_not_to_say',
  ];

  @override
  void initState() {
    super.initState();

    final profile = BagiIdentityController.profile;

    _gender = profile?.gender;
    _preferredTitle = profile?.preferredTitle;
    _preferredNameController.text = _preferredTitle?.trim() ?? '';
  }

  @override
  void dispose() {
    _preferredNameController.dispose();
    super.dispose();
  }

  String _genderLabel(String value) {
    switch (value) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'prefer_not_to_say':
        return 'Prefer not to say';
      default:
        return value;
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    final preferredTitle = _preferredNameController.text.trim();

    if (preferredTitle.isEmpty) {
      _showMessage(
        'Please enter how you would like Bagi to call you.',
        isError: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final success = await BagiIdentityController.saveIdentity(
      gender: _gender,
      preferredTitle: preferredTitle,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    if (!success) {
      _showMessage(
        'Unable to save your Bagi identity. Please try again.',
        isError: true,
      );
      return;
    }

    setState(() {
      _preferredTitle = preferredTitle;
    });

    Navigator.pop(context, true);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }

  Widget _buildGenderOption(String value) {
    final selected = _gender == value;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _saving
          ? null
          : () {
              setState(() {
                _gender = value;
              });
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            RadioGroup<String>(
              groupValue: _gender,
              onChanged: (value) {
                if (_saving) return;

                setState(() {
                  _gender = value;
                });
              },
              child: Radio<String>(value: value, activeColor: _orange),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _genderLabel(value),
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bagi'), centerTitle: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: _orange, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What should Bagi call you?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Enter a name or title that feels natural to you.',
                          style: TextStyle(height: 1.45, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'How should Bagi call you?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _preferredNameController,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Example: Papa, Mama, Ayah, Bunda...',
                prefixIcon: const Icon(Icons.record_voice_over_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Gender',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'This helps personalize your experience with Bagi.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            ..._genderOptions.map(_buildGenderOption),
            const SizedBox(height: 30),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Saving...' : 'Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
