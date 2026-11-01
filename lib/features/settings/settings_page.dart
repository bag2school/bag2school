import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bagi_identity_settings_page.dart';
import '../../data/store.dart';
import '../../models/child_profile.dart';
import '../../models/family_models.dart';
import '../../services/owner_tutorial_state.dart';
import '../../services/reminder_content.dart';
import '../../services/reminder_service.dart';
import '../../utils/controllers.dart';
import '../../widgets/app_notification.dart';
import '../../widgets/bagi_tutorial_overlay.dart';
import '../../widgets/child_avatar.dart';
import '../family/family_activity_page.dart';
import '../family/family_settings_page.dart';
import 'local_account_page.dart';

// Settings: account, child profiles, Bagi identity, language and the daily
// reminder switch. Extracted from lib/main.dart (step 5b).

class SettingsPage extends StatefulWidget {
  final bool ownerSetupTutorial;
  final bool familyTutorial;
  final int familyTutorialFirstStep;

  const SettingsPage({
    super.key,
    this.ownerSetupTutorial = false,
    this.familyTutorial = false,
    this.familyTutorialFirstStep = 15,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey _ownerTutorialAddChildKey = GlobalKey();
  final GlobalKey _ownerTutorialBackKey = GlobalKey();
  final GlobalKey _tutorialChildNameKey = GlobalKey();
  final GlobalKey _tutorialChildGradeKey = GlobalKey();
  final GlobalKey _tutorialChildSaveKey = GlobalKey();
  final FocusNode _tutorialChildNameFocusNode = FocusNode();
  final FocusNode _tutorialChildGradeFocusNode = FocusNode();
  Future<bool>? _ownerTutorialChildEditorRoute;
  final GlobalKey _familyTutorialTileKey = GlobalKey();
  Future<bool?>? _familyTutorialPageRoute;
  bool _ownerSetupTutorialStarted = false;
  bool _familyTutorialStarted = false;

  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);
  static const Color _orange = Color(0xFFFF7A21);
  static const Color _purple = Color(0xFF7661D8);
  static const Color _blue = Color(0xFF4C8FD9);
  static const Color _teal = Color(0xFF2A9D8F);
  static const Color _cream = Color(0xFFFFFCF8);

  @override
  void initState() {
    super.initState();
    if (widget.ownerSetupTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_runOwnerSetupTutorial());
      });
    }
    if (widget.familyTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_runFamilySettingsTutorial());
      });
    }
  }

  @override
  void dispose() {
    _tutorialChildNameFocusNode.dispose();
    _tutorialChildGradeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _runOwnerSetupTutorial() async {
    if (_ownerSetupTutorialStarted || !mounted) return;
    _ownerSetupTutorialStarted = true;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null ||
        Bag2SchoolStore.familyMemberForCurrentAccount()?.role !=
            FamilyMemberRole.owner) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    final addChildContext = _ownerTutorialAddChildKey.currentContext;
    if (addChildContext == null || !addChildContext.mounted) return;
    await Scrollable.ensureVisible(
      addChildContext,
      duration: const Duration(milliseconds: 300),
      alignment: 0.72,
    );
    if (!mounted) return;

    final action = await showBagiTutorialSpotlight(
      context: context,
      targetKey: _ownerTutorialAddChildKey,
      stepLabel: 'Step 2 of 17',
      title: 'Add your child’s profile',
      message: 'Tap Add Child to open your child’s profile form.',
      targetActionId: 'owner-add-child',
    );
    if (!mounted) return;
    if (action == BagiTutorialAction.skip) {
      await OwnerTutorialState.markCompleted(userId);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final saved = action == BagiTutorialAction.targetTapped
        ? await (_ownerTutorialChildEditorRoute ?? Future<bool>.value(false))
        : await _showChildEditor(tutorial: true, tutorialUserId: userId);
    if (!mounted) return;
    if (!saved) return;
    final tutorialCompleted = await OwnerTutorialState.isCompleted(userId);
    if (!mounted) return;
    if (tutorialCompleted) {
      Navigator.of(context).pop();
      return;
    }

    final returnHomeAction = await showBagiTutorialSpotlight(
      context: context,
      targetKey: _ownerTutorialBackKey,
      stepLabel: 'Step 6 of 17',
      title: 'Return to Home',
      message: saved
          ? 'Tap the back arrow to return to Home and continue the tour.'
          : 'Tap the back arrow to return to Home and continue the tour.',
      targetActionId: 'owner-return-home',
    );
    if (!mounted) return;
    if (returnHomeAction == BagiTutorialAction.skip) {
      await OwnerTutorialState.markCompleted(userId);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (returnHomeAction != BagiTutorialAction.targetTapped) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _runFamilySettingsTutorial() async {
    if (_familyTutorialStarted || !mounted) return;
    _familyTutorialStarted = true;
    await WidgetsBinding.instance.endOfFrame;
    final targetContext = _familyTutorialTileKey.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(targetContext, alignment: 0.6);
    if (!mounted) return;
    final action = await showBagiTutorialSpotlight(
      context: context,
      targetKey: _familyTutorialTileKey,
      stepLabel:
          'Step ${widget.familyTutorialFirstStep} of ${widget.familyTutorialFirstStep + 2}',
      title: 'Family settings',
      message: 'This page shows family members, their roles, and the child profiles shared with this family.',
      targetActionId: 'open-family-settings-tutorial',
    );
    if (!mounted) return;
    if (action == BagiTutorialAction.skip) {
      Navigator.of(context).pop(false);
      return;
    }
    bool? pageCompleted;
    if (action == BagiTutorialAction.targetTapped) {
      pageCompleted = await _familyTutorialPageRoute;
    } else {
      pageCompleted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => FamilySettingsPage(
            tutorial: true,
            tutorialStep: widget.familyTutorialFirstStep + 1,
          ),
        ),
      );
    }
    if (mounted) Navigator.of(context).pop(pageCompleted == true);
  }

  Future<void> _runChildFormTutorial(
    BuildContext dialogContext,
    String userId,
    TextEditingController nameController,
    TextEditingController gradeController,
  ) async {
    if (!dialogContext.mounted) return;
    FocusScope.of(dialogContext).requestFocus(_tutorialChildNameFocusNode);
    final nameAction = await showBagiTutorialSpotlight(
      context: dialogContext,
      targetKey: _tutorialChildNameKey,
      stepLabel: 'Step 3 of 17',
      title: 'Your child’s name',
      message:
          'Enter your child’s name, then pick Boy or Girl below so the avatar '
          'matches. Tap Continue when ready.',
      requireNonEmptyController: nameController,
    );
    if (!dialogContext.mounted) return;
    if (nameAction == BagiTutorialAction.skip) {
      await OwnerTutorialState.markCompleted(userId);
      return;
    }

    FocusScope.of(dialogContext).requestFocus(_tutorialChildGradeFocusNode);
    final gradeAction = await showBagiTutorialSpotlight(
      context: dialogContext,
      targetKey: _tutorialChildGradeKey,
      stepLabel: 'Step 4 of 17',
      title: 'Choose a grade',
      message: 'Enter your child’s grade, then tap Continue.',
      requireNonEmptyController: gradeController,
    );
    if (!dialogContext.mounted) return;
    if (gradeAction == BagiTutorialAction.skip) {
      await OwnerTutorialState.markCompleted(userId);
      return;
    }

    FocusScope.of(dialogContext).unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!dialogContext.mounted) return;

    final saveAction = await showBagiTutorialSpotlight(
      context: dialogContext,
      targetKey: _tutorialChildSaveKey,
      stepLabel: 'Step 5 of 17',
      title: 'Save the profile',
      message: 'Tap Save to finish your child’s profile.',
      targetActionId: 'owner-save-child',
    );
    if (!dialogContext.mounted) return;
    if (saveAction == BagiTutorialAction.skip) {
      await OwnerTutorialState.markCompleted(userId);
    }
  }

  String get _languageLabel =>
      Bag2SchoolStore.languageCode == 'id' ? 'Bahasa Indonesia' : 'English';

  Future<void> _chooseLanguage() async {
    var selectedLanguage = Bag2SchoolStore.languageCode;

    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _cream,
            title: const Text(
              'Language',
              style: TextStyle(fontWeight: FontWeight.w900, color: _orange),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: 'en',
                  groupValue: selectedLanguage,
                  title: const Text('English'),
                  activeColor: _orange,
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedLanguage = value);
                  },
                ),
                RadioListTile<String>(
                  value: 'id',
                  groupValue: selectedLanguage,
                  title: const Text('Bahasa Indonesia'),
                  activeColor: _orange,
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedLanguage = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, selectedLanguage),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted || selected == null) return;
    setState(() {
      Bag2SchoolStore.languageCode = selected;
    });

    showAppNotification(
      context,
      title: 'Language updated',
      message:
          'Language changed to ${selected == 'id' ? 'Bahasa Indonesia' : 'English'}.',
      icon: Icons.language_rounded,
    );
  }

  Future<void> _editChildProfile() async {
    final nameController = TextEditingController(
      text: Bag2SchoolStore.childName,
    );
    final gradeController = TextEditingController(
      text: Bag2SchoolStore.childGrade,
    );

    final activeChild = Bag2SchoolStore.activeChild;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        title: const Text(
          'Child Profile',
          style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE7D2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👦🏻', style: TextStyle(fontSize: 52)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gradeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, {'action': 'delete'});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete child'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final grade = gradeController.text.trim();

              if (name.isEmpty || grade.isEmpty) return;

              Navigator.pop(dialogContext, {
                'action': 'save',
                'name': name,
                'grade': grade,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      disposeControllersAfterRoute([nameController, gradeController]);
    });

    if (!mounted || result == null) return;

    if (result['action'] == 'delete') {
      final childName = Bag2SchoolStore.childName;

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (warningContext) {
          return AlertDialog(
            backgroundColor: _cream,
            title: const Text(
              'Delete child?',
              style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
            ),
            content: Text(
              'Are you sure you want to delete $childName? '
              'This child will be removed from your family. '
              'This action can\'t be undone.',
              style: const TextStyle(color: _muted, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(warningContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(warningContext, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete child'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      final success = await Bag2SchoolStore.deleteActiveChild();

      if (!mounted) return;

      if (success) {
        setState(() {});

        showAppNotification(
          context,
          title: 'Child deleted',
          message: '$childName has been removed from your family.',
          icon: Icons.delete_outline_rounded,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this child. Please try again.'),
          ),
        );
      }

      return;
    }

    setState(() {
      Bag2SchoolStore.updateActiveChild(
        name: result['name'],
        grade: result['grade'],
      );
    });
  }

  void _showComingSoon(String title, String description) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 9),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w900,
          color: _muted,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 11.5, color: _muted),
          ),
        ),
        trailing:
            trailing ?? const Icon(Icons.chevron_right_rounded, color: _muted),
      ),
    );
  }

  Widget _buildAccountCard() {
    final account = Bag2SchoolStore.currentAccount;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account?.displayName ?? 'My Account',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  account?.email ?? 'Not signed in',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocalAccountPage()),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(_orange),
              side: const WidgetStatePropertyAll(
                BorderSide(color: Color(0xFFFFC18F)),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              ),
            ),
            child: Text(
              account == null ? 'Sign in' : 'Manage',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showChildEditor({
    ChildProfile? child,
    bool tutorial = false,
    String? tutorialUserId,
  }) async {
    final nameController = TextEditingController(text: child?.name ?? '');
    final gradeController = TextEditingController(text: child?.grade ?? '');
    var selectedGender = (child?.gender?.trim().isNotEmpty ?? false)
        ? child!.gender
        : null;
    var childTutorialStarted = false;
    var isSaving = false;
    String? saveError;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        if (tutorial && tutorialUserId != null && !childTutorialStarted) {
          childTutorialStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (dialogContext.mounted) {
              unawaited(
                _runChildFormTutorial(
                  dialogContext,
                  tutorialUserId,
                  nameController,
                  gradeController,
                ),
              );
            }
          });
        }
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            backgroundColor: _cream,
            title: Text(
              child == null ? 'Add Child' : 'Child Profile',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: _orange,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChildAvatar(gender: selectedGender, size: 92),
                  const SizedBox(height: 16),
                  TextField(
                    key: tutorial ? _tutorialChildNameKey : null,
                    focusNode: tutorial ? _tutorialChildNameFocusNode : null,
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: tutorial ? _tutorialChildGradeKey : null,
                    focusNode: tutorial ? _tutorialChildGradeFocusNode : null,
                    controller: gradeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Grade',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'boy',
                            label: Text('Boy'),
                            icon: Icon(Icons.male_rounded, size: 18),
                          ),
                          ButtonSegment(
                            value: 'girl',
                            label: Text('Girl'),
                            icon: Icon(Icons.female_rounded, size: 18),
                          ),
                        ],
                        selected: {selectedGender ?? 'boy'},
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                        onSelectionChanged: (value) {
                          setDialogState(() => selectedGender = value.first);
                        },
                      ),
                    ),
                  ),
                  if (saveError != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        saveError!,
                        style: const TextStyle(
                          color: Color(0xFFB3261E),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),

              // Delete hanya muncul ketika sedang EDIT child.
              if (child != null)
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext, {'action': 'delete'});
                        },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete child'),
                ),

              FilledButton(
                key: tutorial ? _tutorialChildSaveKey : null,
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final grade = gradeController.text.trim();

                        if (name.isEmpty || grade.isEmpty) return;

                        if (tutorial) {
                          BagiTutorialTargetActions.activate(
                            'owner-save-child',
                          );
                        }

                        if (child == null) {
                          final familyId = Bag2SchoolStore.currentFamilyId;
                          if (familyId == null || familyId.isEmpty) {
                            setDialogState(() {
                              saveError = Bag2SchoolStore.languageCode == 'id'
                                  ? 'Informasi keluarga belum tersedia. Silakan masuk kembali lalu coba lagi.'
                                  : 'Family information is unavailable. Please sign in again and try once more.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                            saveError = null;
                          });

                          try {
                            final row = await Supabase.instance.client
                                .from('children')
                                .insert({
                                  'family_id': familyId,
                                  'name': name,
                                  'grade': grade,
                                  'gender': selectedGender,
                                })
                                .select()
                                .single();
                            final id = row['id']?.toString();
                            if (id == null || id.isEmpty) {
                              throw Exception(
                                'Supabase did not return a child ID.',
                              );
                            }
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext, {
                              'action': 'save',
                              'name': name,
                              'grade': grade,
                              'id': id,
                              'gender': selectedGender ?? '',
                            });
                          } catch (error, stackTrace) {
                            debugPrint('[BagiChild] ADD CHILD FAILED: $error');
                            debugPrintStack(stackTrace: stackTrace);
                            if (!dialogContext.mounted) return;
                            setDialogState(() {
                              isSaving = false;
                              saveError = Bag2SchoolStore.languageCode == 'id'
                                  ? 'Bagi belum bisa menyimpan profil ini. Periksa koneksi internet dan coba lagi.'
                                  : 'Bagi could not save this profile yet. Check your internet connection and try again.';
                            });
                          }
                          return;
                        }

                        Navigator.pop(dialogContext, {
                          'action': 'save',
                          'name': name,
                          'grade': grade,
                          'gender': selectedGender ?? '',
                        });
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      disposeControllersAfterRoute([nameController, gradeController]);
    });

    if (!mounted || result == null) return false;

    final action = result['action'];

    // =========================================================
    // DELETE CHILD
    // =========================================================
    if (action == 'delete' && child != null) {
      final childName = child.name;

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (warningContext) => AlertDialog(
          backgroundColor: _cream,
          title: const Text(
            'Delete child?',
            style: TextStyle(fontWeight: FontWeight.w900, color: _ink),
          ),
          content: Text(
            'Are you sure you want to delete $childName? '
            'This child will be removed from your family. '
            'This action can\'t be undone.',
            style: const TextStyle(color: _muted, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(warningContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(warningContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete child'),
            ),
          ],
        ),
      );

      if (confirmed != true) return false;

      final success = await Bag2SchoolStore.deleteChild(child.id);

      if (!mounted) return false;

      if (success) {
        setState(() {});

        showAppNotification(
          context,
          title: 'Child deleted',
          message: '$childName has been removed from your family.',
          icon: Icons.delete_outline_rounded,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete this child. Please try again.'),
          ),
        );
      }

      return false;
    }

    // =========================================================
    // SAVE / ADD CHILD
    // =========================================================
    if (action == 'save') {
      if (child == null) {
        final id = result['id'];
        if (id == null || id.isEmpty) return false;
        if (!mounted) return false;
        setState(() {
          Bag2SchoolStore.childProfiles.add(
            ChildProfile(
              id: id,
              name: result['name']!,
              grade: result['grade']!,
              gender: (result['gender']?.isEmpty ?? true)
                  ? null
                  : result['gender'],
            ),
          );

          Bag2SchoolStore.switchActiveChild(id);
        });

        if (!tutorial) {
          showAppNotification(
            context,
            title: 'Child added',
            message: '${result['name']} has been added to your family.',
            icon: Icons.person_add_alt_1_rounded,
          );
        } else {
          // The tutorial used to end the save step silently.
          showAppNotification(
            context,
            title: 'Child saved!',
            message:
                '${result['name']} is ready. Bagi will use this profile from '
                'now on.',
            icon: Icons.check_circle_rounded,
          );
        }
        return true;
      } else {
        final index = Bag2SchoolStore.childProfiles.indexWhere(
          (entry) => entry.id == child.id,
        );

        if (index >= 0) {
          setState(() {
            Bag2SchoolStore.childProfiles[index] = child.copyWith(
              name: result['name'],
              grade: result['grade'],
              gender: (result['gender']?.isEmpty ?? true)
                  ? null
                  : result['gender'],
            );
          });
        }

        // Persist the edit, otherwise it disappears on the next load.
        try {
          await Supabase.instance.client
              .from('children')
              .update({
                'name': result['name'],
                'grade': result['grade'],
                'gender': (result['gender']?.isEmpty ?? true)
                    ? null
                    : result['gender'],
              })
              .eq('id', child.id);
        } catch (error) {
          debugPrint('[BagiChild] UPDATE CHILD FAILED: $error');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Saved on this device, but the server could not be updated.',
                ),
              ),
            );
          }
        }

        return true;
      }
    }
    return false;
  }

  Future<void> _chooseSettingsChild() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 18),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                'Select Active Child',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ),
            ...Bag2SchoolStore.childProfiles.map(
              (child) => ListTile(
                leading: ChildAvatar(
                  avatarUrl: child.avatarUrl,
                  gender: child.gender,
                  size: 40,
                ),
                title: Text(
                  child.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(child.grade),
                trailing: child.id == Bag2SchoolStore.activeChildId
                    ? const Icon(Icons.check_circle_rounded, color: _orange)
                    : null,
                onTap: () => Navigator.pop(sheetContext, child.id),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selected == null) return;

    setState(() {
      Bag2SchoolStore.signInLocal(selected);
    });

    final account = Bag2SchoolStore.currentAccount;

    showAppNotification(
      context,
      title: 'Signed In',
      message: '${account?.displayName ?? 'Account'} is now active.',
      icon: Icons.login_rounded,
    );
  }

  /// Tapping a child profile in Settings makes it the active one, which is the
  /// same switch used from Home.
  void _activateChild(ChildProfile child) {
    if (child.id == Bag2SchoolStore.activeChildId) return;

    setState(() {
      Bag2SchoolStore.switchActiveChild(child.id);
    });

    showAppNotification(
      context,
      title: 'Profile switched',
      message: '${child.name} is now the active profile.',
      icon: Icons.swap_horiz_rounded,
    );
  }

  Widget _buildChildProfilesSection({required bool canManage}) {
    return Column(
      children: [
        _sectionTitle('Child Profiles'),
        ...Bag2SchoolStore.childProfiles.map(
          (child) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .035),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              onTap: () => _activateChild(child),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 5,
              ),
              leading: ChildAvatar(
                avatarUrl: child.avatarUrl,
                gender: child.gender,
                size: 48,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      child.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                  ),
                  if (child.id == Bag2SchoolStore.activeChildId)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBDD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: .6,
                          fontWeight: FontWeight.w900,
                          color: _orange,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(child.grade),
              trailing: canManage
                  ? IconButton(
                      onPressed: () => _showChildEditor(child: child),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: _muted,
                        size: 20,
                      ),
                      tooltip: 'Edit ${child.name}',
                    )
                  : null,
            ),
          ),
        ),
        if (canManage)
          OutlinedButton.icon(
            onPressed: () {
              if (widget.ownerSetupTutorial) {
                BagiTutorialTargetActions.activate('owner-add-child');
                _ownerTutorialChildEditorRoute = _showChildEditor(
                  tutorial: true,
                  tutorialUserId: Supabase.instance.client.auth.currentUser?.id,
                );
              } else {
                _showChildEditor();
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Child'),
            key: _ownerTutorialAddChildKey,
            style: OutlinedButton.styleFrom(
              foregroundColor: _orange,
              side: const BorderSide(color: Color(0xFFFFC18F)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = Bag2SchoolStore.familyMemberForCurrentAccount()?.role;

    debugPrint('========================================');
    debugPrint('[Settings] CURRENT ROLE: $currentRole');
    debugPrint(
      '[Settings] CURRENT USER: '
      '${Supabase.instance.client.auth.currentUser?.email}',
    );
    debugPrint(
      '[Settings] FAMILY MEMBER: '
      '${Bag2SchoolStore.familyMemberForCurrentAccount()?.displayName}',
    );
    debugPrint('========================================');
    final canManageChildren = currentRole == FamilyMemberRole.owner;
    final isOwner = currentRole == FamilyMemberRole.owner;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        leading: IconButton(
          key: _ownerTutorialBackKey,
          onPressed: () {
            if (widget.ownerSetupTutorial) {
              BagiTutorialTargetActions.activate('owner-return-home');
              Navigator.of(context).pop(true);
            } else {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w900, color: _orange),
        ),
        backgroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
        children: [
          _buildAccountCard(),
          const SizedBox(height: 12),

          if (Bag2SchoolStore.isSignedIn)
            _buildChildProfilesSection(canManage: canManageChildren),

          _sectionTitle('Account & Family'),
          _settingTile(
            icon: Icons.person_outline_rounded,
            color: _orange,
            title: 'Account',
            subtitle: Bag2SchoolStore.isSignedIn
                ? (Bag2SchoolStore.currentAccount?.email ?? 'Signed in')
                : 'Not signed in',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocalAccountPage()),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),

          _settingTile(
            icon: Icons.auto_awesome_rounded,
            color: _orange,
            title: '✨ Bagi',
            subtitle: 'Choose how Bagi should call you',
            onTap: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const BagiIdentitySettingsPage(),
                ),
              );

              if (!context.mounted || updated != true) return;

              setState(() {});

              showAppNotification(
                context,
                title: 'Bagi updated',
                message: 'Your Bagi identity has been updated successfully.',
                icon: Icons.auto_awesome_rounded,
              );
            },
          ),

          KeyedSubtree(
            key: widget.familyTutorial ? _familyTutorialTileKey : null,
            child: _settingTile(
              icon: Icons.family_restroom_rounded,
              color: _purple,
              title: 'Family',
              subtitle: 'Members, children and access',
              onTap: () {
                if (widget.familyTutorial) {
                  BagiTutorialTargetActions.activate(
                    'open-family-settings-tutorial',
                  );
                  _familyTutorialPageRoute = Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FamilySettingsPage(
                        tutorial: true,
                        tutorialStep: widget.familyTutorialFirstStep + 1,
                      ),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FamilySettingsPage()),
                ).then((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          ),

          _sectionTitle('Data & Sync'),
          _settingTile(
            icon: Icons.cloud_outlined,
            color: _blue,
            title: 'Cloud Backup & Sync',
            subtitle: 'Keep Bag2School data safe across devices',
            onTap: () => _showComingSoon(
              'Cloud Backup & Sync',
              'Cloud backup will be implemented before multi-device family synchronization.',
            ),
          ),

          _sectionTitle('Notifications'),
          const _DailyReminderTile(),
          _settingTile(
            icon: Icons.notifications_none_rounded,
            color: _orange,
            title: 'Family Activity',
            subtitle: 'See who added, edited or deleted family data',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyActivityPage()),
              );
            },
          ),

          _sectionTitle('Language'),
          _settingTile(
            icon: Icons.language_rounded,
            color: _orange,
            title: 'Language',
            subtitle: _languageLabel,
            onTap: _chooseLanguage,
          ),

          _sectionTitle('Subscription'),
          _settingTile(
            icon: Icons.workspace_premium_outlined,
            color: _teal,
            title: 'Subscription',
            subtitle: 'Bag2School Free',
            onTap: () => _showComingSoon(
              'Subscription',
              'Subscription will be added when the premium feature set is ready.',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'FREE',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: .7,
                  fontWeight: FontWeight.w900,
                  color: _teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyReminderTile extends StatefulWidget {
  const _DailyReminderTile();

  @override
  State<_DailyReminderTile> createState() => _DailyReminderTileState();
}

class _DailyReminderTileState extends State<_DailyReminderTile> {
  static const Color _ink = Color(0xFF302722);
  static const Color _muted = Color(0xFF756B65);
  static const Color _orange = Color(0xFFFF7A21);

  bool _enabled = false;
  int _hour = DailyReminder.defaultHour;
  int _minute = DailyReminder.defaultMinute;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await DailyReminder.isEnabled();
    final hour = await DailyReminder.reminderHour();
    final minute = await DailyReminder.reminderMinute();

    if (!mounted) return;

    setState(() {
      _enabled = enabled;
      _hour = hour;
      _minute = minute;
    });
  }

  String get _timeLabel => DailyReminder.describeTime(_hour, _minute);

  Future<void> _toggle(bool value) async {
    setState(() {
      _busy = true;
      _message = null;
    });

    if (value) {
      final granted = await DailyReminder.requestPermissions();

      if (!granted) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _message =
              'Notification permission is not granted yet. Allow '
              'notifications for Bag2School in Android settings.';
        });
        return;
      }
    }

    await DailyReminder.saveEnabled(value);
    await refreshDailyReminder();

    if (!mounted) return;

    setState(() {
      _enabled = value;
      _busy = false;
      _message = value
          ? 'Bagi will check in at $_timeLabel every evening.'
          : null;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );

    if (picked == null || !mounted) return;

    await DailyReminder.saveTime(hour: picked.hour, minute: picked.minute);
    await refreshDailyReminder();

    if (!mounted) return;

    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
      if (_enabled) {
        _message = 'Bagi will check in at $_timeLabel every evening.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: _busy ? null : _toggle,
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: _orange,
            ),
            title: const Text(
              'Daily reminder',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            subtitle: const Text(
              'Bagi checks in every evening about tomorrow',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ),
          if (_enabled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: _busy ? null : _pickTime,
              leading: const Icon(Icons.schedule_rounded, color: _muted),
              title: const Text(
                'Reminder time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              trailing: Text(
                _timeLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _orange,
                ),
              ),
            ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 2),
              child: Text(
                _message!,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: _muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
