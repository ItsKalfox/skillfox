import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  
  Future<String> uploadMedia(File file, String folderName) async {
    try {
     
      String ext = file.path.split('.').last; 
      String fileName = '$folderName/${DateTime.now().millisecondsSinceEpoch}.$ext';
      Reference ref = _storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }
}