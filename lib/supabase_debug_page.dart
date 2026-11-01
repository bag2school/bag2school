import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDebugPage extends StatefulWidget {
  const SupabaseDebugPage({super.key});

  @override
  State<SupabaseDebugPage> createState() => _SupabaseDebugPageState();
}

class _SupabaseDebugPageState extends State<SupabaseDebugPage> {
  String status = 'No test has been performed yet.';
  bool loading = false;

  static const String kennethChildId = 'b17d3c83-a0cf-4413-ab17-2f7cabd79672';

  static const String kennethFamilyId = 'c40c8dd1-d313-4a1c-85db-239aefee36a6';

  static const String familyMemberId = '7d575f48-53ee-4ca1-bbb9-4050acd02d4c';

  Future<void> testOwnerLogin() async {
    setState(() {
      loading = true;
      status = 'Testing Owner login...';
    });

    try {
      final client = Supabase.instance.client;

      final response = await client.auth.signInWithPassword(
        email: 'owner@bag2school.local',
        password: 'Bag2School@2026',
      );

      if (!mounted) return;

      final user = response.user;

      if (user == null) {
        setState(() {
          status = 'OWNER LOGIN FAILED\n\nUser was not returned.';
          loading = false;
        });
        return;
      }

      setState(() {
        status =
            '''
OWNER LOGIN SUCCESS

UID:
${user.id}

Email:
${user.email}
''';
        loading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
SUPABASE AUTH ERROR

Message:
${e.message}

Status:
${e.statusCode ?? '-'}
''';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
ERROR

$e
''';
        loading = false;
      });
    }
  }

  Future<void> testOwnerDataAccess() async {
    setState(() {
      loading = true;
      status = 'Testing Owner database access...';
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          status = '''
DATA ACCESS FAILED

No authenticated Owner session.

Please press "Test Owner Login" first.
''';
          loading = false;
        });
        return;
      }

      final rows = await client.from('children').select();

      if (!mounted) return;

      setState(() {
        status =
            '''
OWNER DATABASE ACCESS SUCCESS

Authenticated UID:
${user.id}

Children rows returned:
${rows.length}

Data:
$rows
''';
        loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
DATABASE / RLS ERROR

Message:
${e.message}

Code:
${e.code ?? '-'}

Details:
${e.details}

Hint:
${e.hint ?? '-'}
''';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
DATABASE ACCESS ERROR

$e
''';
        loading = false;
      });
    }
  }

  Future<void> testChildAccessGrants() async {
    setState(() {
      loading = true;
      status = 'Testing child access grants...';
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          status = '''
GRANT ACCESS FAILED

No authenticated Owner session.

Please press "Test Owner Login" first.
''';
          loading = false;
        });
        return;
      }

      final rows = await client.from('child_access_grants').select();

      if (!mounted) return;

      setState(() {
        status =
            '''
CHILD ACCESS GRANTS SUCCESS

Authenticated UID:
${user.id}

Grant rows returned:
${rows.length}

Data:
$rows
''';
        loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
CHILD ACCESS GRANTS RLS ERROR

Message:
${e.message}

Code:
${e.code ?? '-'}

Details:
${e.details}

Hint:
${e.hint ?? '-'}
''';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
CHILD ACCESS GRANTS ERROR

$e
''';
        loading = false;
      });
    }
  }

  Future<void> testFamilyMembersAccess() async {
    setState(() {
      loading = true;
      status = 'Testing family members access...';
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          status = '''
FAMILY MEMBERS ACCESS FAILED

No authenticated Owner session.

Please press "Test Owner Login" first.
''';
          loading = false;
        });
        return;
      }

      final rows = await client
          .from('family_members')
          .select()
          .eq('family_id', kennethFamilyId);

      if (!mounted) return;

      setState(() {
        status =
            '''
FAMILY MEMBERS ACCESS SUCCESS

Authenticated UID:
${user.id}

Family ID:
$kennethFamilyId

Family members returned:
${rows.length}

Data:
$rows
''';
        loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
FAMILY MEMBERS RLS ERROR

Message:
${e.message}

Code:
${e.code ?? '-'}

Details:
${e.details}

Hint:
${e.hint ?? '-'}
''';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
FAMILY MEMBERS ACCESS ERROR

$e
''';
        loading = false;
      });
    }
  }

  Future<void> testOwnProfileAccess() async {
    setState(() {
      loading = true;
      status = 'Testing own profile access...';
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          status = '''
PROFILE ACCESS FAILED

No authenticated Owner session.

Please press "Test Owner Login" first.
''';
          loading = false;
        });
        return;
      }

      final profile = await client
          .from('profiles')
          .select(
            'id, display_name, avatar_url, language, '
            'gender, preferred_title',
          )
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        setState(() {
          status =
              '''
PROFILE ACCESS FAILED

Authenticated UID:
${user.id}

No own profile was returned.
''';
          loading = false;
        });
        return;
      }

      setState(() {
        status =
            '''
OWN PROFILE ACCESS SUCCESS

Authenticated UID:
${user.id}

Profile ID:
${profile['id']}

Display Name:
${profile['display_name']}

Language:
${profile['language']}

Gender:
${profile['gender'] ?? '-'}

Preferred Title:
${profile['preferred_title'] ?? '-'}

Avatar URL:
${profile['avatar_url'] ?? '-'}
''';
        loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
PROFILE RLS ERROR

Message:
${e.message}

Code:
${e.code ?? '-'}

Details:
${e.details}

Hint:
${e.hint ?? '-'}
''';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
PROFILE ACCESS ERROR

$e
''';
        loading = false;
      });
    }
  }

  Future<void> testOwnerIdentity() async {
    setState(() {
      loading = true;
      status = 'Testing Owner identity...';
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          status = '''
OWNER IDENTITY FAILED

No authenticated Owner session.

Please press "Test Owner Login" first.
''';
          loading = false;
        });
        return;
      }

      final profile = await client
          .from('profiles')
          .select('id, display_name, gender, preferred_title')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        if (!mounted) return;

        setState(() {
          status =
              '''
OWNER IDENTITY FAILED

No profile found for:
${user.id}
''';
          loading = false;
        });
        return;
      }

      final familyMember = await client
          .from('family_members')
          .select(
            'id, family_id, profile_id, role, '
            'display_name, relationship',
          )
          .eq('profile_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (familyMember == null) {
        setState(() {
          status =
              '''
OWNER IDENTITY PARTIAL SUCCESS

Profile found:

Display Name:
${profile['display_name']}

Gender:
${profile['gender'] ?? '-'}

Preferred Title:
${profile['preferred_title'] ?? '-'}

But no family member record was returned.
''';
          loading = false;
        });
        return;
      }

      setState(() {
        status =
            '''
OWNER IDENTITY SUCCESS

Display Name:
${profile['display_name']}

Gender:
${profile['gender'] ?? '-'}

Preferred Title:
${profile['preferred_title'] ?? '-'}

Role:
${familyMember['role']}

Relationship:
${familyMember['relationship'] ?? '-'}

Family ID:
${familyMember['family_id']}
''';
        loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
OWNER IDENTITY RLS ERROR

Message:
${e.message}

Code:
${e.code ?? '-'}

Details:
${e.details}

Hint:
${e.hint ?? '-'}
''';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
OWNER IDENTITY ERROR

$e
''';
        loading = false;
      });
    }
  }

  Future<void> testChildPermissionResolution() async {
    setState(() {
      loading = true;
      status = 'Testing child permission resolution...';
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          status = '''
PERMISSION TEST FAILED

No authenticated Owner session.

Please press "Test Owner Login" first.
''';
          loading = false;
        });
        return;
      }

      final grant = await client
          .from('child_access_grants')
          .select(
            'id, child_id, family_member_id, '
            'view_schedule, edit_schedule, '
            'view_homework, edit_homework, '
            'view_preparation, edit_preparation, '
            'view_exam, edit_exam',
          )
          .eq('child_id', kennethChildId)
          .eq('family_member_id', familyMemberId)
          .maybeSingle();

      if (!mounted) return;

      if (grant == null) {
        setState(() {
          status =
              '''
PERMISSION TEST FAILED

No grant was found for:

Child:
$kennethChildId

Family Member:
$familyMemberId
''';
          loading = false;
        });
        return;
      }

      final viewSchedule = grant['view_schedule'] == true;
      final editSchedule = grant['edit_schedule'] == true;
      final viewHomework = grant['view_homework'] == true;
      final editHomework = grant['edit_homework'] == true;
      final viewPreparation = grant['view_preparation'] == true;
      final editPreparation = grant['edit_preparation'] == true;
      final viewExam = grant['view_exam'] == true;
      final editExam = grant['edit_exam'] == true;

      setState(() {
        status =
            '''
CHILD PERMISSION RESOLUTION SUCCESS

Authenticated UID:
${user.id}

Child:
Kenneth

Child ID:
$kennethChildId

Family Member ID:
$familyMemberId

Permissions:

Schedule
  View: $viewSchedule
  Edit: $editSchedule

Homework
  View: $viewHomework
  Edit: $editHomework

Preparation
  View: $viewPreparation
  Edit: $editPreparation

Exam
  View: $viewExam
  Edit: $editExam
''';
        loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
PERMISSION RLS ERROR

Message:
${e.message}

Code:
${e.code ?? '-'}

Details:
${e.details}

Hint:
${e.hint ?? '-'}
''';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status =
            '''
PERMISSION TEST ERROR

$e
''';
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      setState(() {
        status = 'Owner logged out successfully.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status = 'LOGOUT ERROR\n\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Debug')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cloud_done_outlined, size: 72),
              const SizedBox(height: 24),
              const Text(
                'Bag2School Supabase Test',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SelectableText(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: loading ? null : testOwnerLogin,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(loading ? 'Testing...' : 'Test Owner Login'),
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: loading ? null : testOwnerDataAccess,
                icon: const Icon(Icons.storage_outlined),
                label: const Text('Test Owner Data Access'),
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: loading ? null : testChildAccessGrants,
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Test Child Access Grants'),
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: loading ? null : testFamilyMembersAccess,
                icon: const Icon(Icons.family_restroom_outlined),
                label: const Text('Test Family Members Access'),
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: loading ? null : testOwnProfileAccess,
                icon: const Icon(Icons.person_outline),
                label: const Text('Test Own Profile'),
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: loading ? null : testOwnerIdentity,
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Test Owner Identity'),
              ),

              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: loading ? null : testChildPermissionResolution,
                icon: const Icon(Icons.lock_open_outlined),
                label: const Text('Test Child Permission'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: loading ? null : logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
