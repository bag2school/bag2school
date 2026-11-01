import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/store.dart';
import '../models/family_models.dart';
import 'bagi_identity_controller.dart';

// Bagi's greeting helpers: who Bagi addresses and how {parent} is filled
// in. Extracted from lib/main.dart (step 5a of the split).

String bagiRoleFallbackName(FamilyMemberRole? role) {
  return switch (role) {
    FamilyMemberRole.owner || FamilyMemberRole.parentGuardian => 'Parent',
    FamilyMemberRole.caregiver => 'Caregiver',
    FamilyMemberRole.child || null => 'there',
  };
}

String? bagiNameFromEmail(String? email) {
  final local = email?.trim().split('@').first ?? '';
  if (local.isEmpty) return null;

  final words = local
      .split(RegExp(r'[._\-+]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .toList();

  return words.isEmpty ? null : words.join(' ');
}

String bagiAccountAddressName() {
  final member = Bag2SchoolStore.familyMemberForCurrentAccount();
  final account = Bag2SchoolStore.currentAccount;
  final user = Supabase.instance.client.auth.currentUser;

  final metadataName = user?.userMetadata?['display_name']?.toString().trim();
  final emailName = bagiNameFromEmail(user?.email);

  // Bagi greets whoever is signed in: the title saved for Bagi comes first
  // inside the controller, then the account's own names.
  return BagiIdentityController.resolveAddressName(
    preferredNames: <String>[
      if (metadataName != null && metadataName.isNotEmpty) metadataName,
      if (member != null) member.displayName,
      if (account != null) account.displayName,
      if (emailName != null) emailName,
    ],
    childNames: Bag2SchoolStore.childProfiles.map((child) => child.name),
    fallbackName: bagiRoleFallbackName(member?.role),
  );
}

String personalizeBagiMessage(String message) {
  return message.replaceAll('{parent}', bagiAccountAddressName());
}
