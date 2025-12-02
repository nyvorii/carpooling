import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class EditProfileScreen extends StatefulWidget {
  final File? currentImage;
  final String currentName;
  final String currentSurname;

  const EditProfileScreen({
    super.key,
    this.currentImage,
    required this.currentName,
    required this.currentSurname,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  File? imageFile;
  String? customPhotoBase64;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _surnameController = TextEditingController(text: widget.currentSurname);
    imageFile = widget.currentImage;

    Future.microtask(_loadCustomPhoto);
  }


  Future<void> _loadCustomPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final base64 = doc.data()?['customPhotoUrl'];

    if (base64 != null && base64.toString().isNotEmpty) {
      setState(() {
        customPhotoBase64 = base64;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _convertToBase64(File image) async {
    return compute(_encodeImageToBase64, image);
  }

  String _encodeImageToBase64(File image) {
    final bytes = image.readAsBytesSync();
    return base64Encode(bytes);
  }


  Future<void> _saveProfile() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final firestore = FirebaseFirestore.instance;

      final String name = _nameController.text.trim();
      final String surname = _surnameController.text.trim();
      final String fullName = "$name $surname".trim();

      if (name.isEmpty || surname.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Imię i nazwisko nie mogą być puste.")),
        );
        return;
      }

      String? base64Image;

      await Future.wait([
        firestore.collection('users').doc(user.uid).set(
          {'displayName': fullName},
          SetOptions(merge: true),
        ),
        user.updateDisplayName(fullName),
      ]);


      if (imageFile != null) {
        base64Image = await _convertToBase64(imageFile!);
        await firestore.collection('users').doc(user.uid).set({
          'customPhotoUrl': base64Image,
        }, SetOptions(merge: true));
      }

      Navigator.pop(context, {
        'image': imageFile,
        'name': name,
        'surname': surname,
        'photoUrl': base64Image != null
            ? 'data:image/png;base64,$base64Image'
            : user.photoURL,
      });
    }
  }

  Widget buildProfilePhoto({
    File? imageFile,
    String? customBase64,
    String? photoUrl,
    double size = 120,
  }) {
    if (imageFile != null) {
      return ClipOval(
        child: Image.file(imageFile, width: size, height: size, fit: BoxFit.cover),
      );
    }

    if (customBase64 != null && customBase64.isNotEmpty) {
      try {
        return ClipOval(
          child: Image.memory(base64Decode(customBase64), width: size, height: size, fit: BoxFit.cover),
        );
      } catch (e) {
        print("Błąd dekodowania Base64: $e");
      }
    }

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(photoUrl, width: size, height: size, fit: BoxFit.cover),
      );
    }

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: Colors.blueAccent,
        child: const Icon(Icons.person, size: 60, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPhotoUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return Scaffold(
      appBar: AppBar(title: const Text('Edytuj profil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildProfilePhoto(
              imageFile: imageFile,
              customBase64: customPhotoBase64,
              photoUrl: userPhotoUrl,
              size: 120,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Wybierz zdjęcie'),
              onPressed: _pickImage,
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Imię'),
            ),
            TextField(
              controller: _surnameController,
              decoration: const InputDecoration(labelText: 'Nazwisko'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Zapisz'),
            ),
          ],
        ),
      ),
    );
  }
}
