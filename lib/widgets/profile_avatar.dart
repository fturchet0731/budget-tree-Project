import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../theme/app_tokens.dart';

/// A user's circular profile picture, decoded from the profile's inline
/// base64 avatar; falls back to a soft person glyph when none is set.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.size = 52});

  final Profile? profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    Uint8List? bytes;
    final b64 = profile?.avatarB64;
    if (b64 != null && b64.isNotEmpty) {
      try {
        bytes = base64Decode(b64);
      } catch (_) {
        bytes = null;
      }
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.accentSoft,
        image: bytes == null
            ? null
            : DecorationImage(
                image: MemoryImage(bytes),
                fit: BoxFit.cover,
              ),
      ),
      child: bytes == null
          ? Icon(Icons.person, color: t.accentStrong, size: size * 0.55)
          : null,
    );
  }
}
