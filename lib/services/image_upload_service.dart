import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 800,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // Upload image to Firebase Storage, return download URL
  Future<String> uploadProductImage(File file) async {
    final id = const Uuid().v4();
    final ref = _storage.ref().child('products/$id.jpg');
    return _upload(file, ref);
  }

  Future<String> uploadProfilePicture(String uid, File file) async {
    final ref = _storage.ref().child('profile_pictures/$uid.jpg');
    return _upload(file, ref);
  }

  Future<String> _upload(File file, Reference ref) async {
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await task.ref.getDownloadURL();
  }

  // Delete image from Storage by URL
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore if already deleted or URL is invalid
    }
  }
}