import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class BagiAvatarService {
  BagiAvatarService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static const String bucketName = 'bag2school-avatars';

  static String childAvatarPath({
    required String childId,
    required String fileName,
  }) {
    return 'children/$childId/$fileName';
  }

  static Future<String> uploadChildAvatar({
    required String childId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final path = childAvatarPath(childId: childId, fileName: fileName);

    await _client.storage
        .from(bucketName)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return path;
  }

  static Future<void> deleteChildAvatar({required String storagePath}) async {
    await _client.storage.from(bucketName).remove([storagePath]);
  }

  static Future<String> createChildAvatarSignedUrl({
    required String storagePath,
    int expiresIn = 3600,
  }) async {
    return _client.storage
        .from(bucketName)
        .createSignedUrl(storagePath, expiresIn);
  }
}
