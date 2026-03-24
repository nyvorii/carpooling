import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum PhotoType { car, idDocument, taxiLicense, driverLicense }

class DriverFormScreen extends StatefulWidget {
  const DriverFormScreen({super.key});

  @override
  State<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends State<DriverFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _carColorController = TextEditingController();
  final TextEditingController _carPlateController = TextEditingController();

  File? _carPhotoFile;
  File? _idDocumentPhotoFile;
  File? _taxiLicensePhotoFile;
  File? _driverLicensePhotoFile;
  
  bool _isLoading = false;

  Future<void> _pickImage(PhotoType type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 30,
    ); 
    
    if (pickedFile != null) {
      setState(() {
        switch (type) {
          case PhotoType.car:
            _carPhotoFile = File(pickedFile.path);
            break;
          case PhotoType.idDocument:
            _idDocumentPhotoFile = File(pickedFile.path);
            break;
          case PhotoType.taxiLicense:
            _taxiLicensePhotoFile = File(pickedFile.path);
            break;
          case PhotoType.driverLicense:
            _driverLicensePhotoFile = File(pickedFile.path);
            break;
        }
      });
    }
  }

  Future<String> _encodePhoto(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_carPhotoFile == null || 
        _idDocumentPhotoFile == null || 
        _taxiLicensePhotoFile == null || 
        _driverLicensePhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proszę dodać wszystkie 4 wymagane zdjęcia!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String carBase64 = await _encodePhoto(_carPhotoFile!);
      String idDocBase64 = await _encodePhoto(_idDocumentPhotoFile!);
      String taxiBase64 = await _encodePhoto(_taxiLicensePhotoFile!);
      String driverBase64 = await _encodePhoto(_driverLicensePhotoFile!);

      await FirebaseFirestore.instance.collection('driver_applications').add({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'carColor': _carColorController.text.trim(),
        'carPlate': _carPlateController.text.trim().toUpperCase(),
        'carPhoto': carBase64,
        'idDocumentPhoto': idDocBase64,
        'taxiLicensePhoto': taxiBase64,
        'driverLicensePhoto': driverBase64,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aplikacja wysłana pomyślnie!')),
      );
      Navigator.pop(context); 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd podczas wysyłania: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _carColorController.dispose();
    _carPlateController.dispose();
    super.dispose();
  }

  Widget _buildImagePickerBox(String title, File? imageFile, PhotoType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickImage(type),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageFile != null
                  ? Image.file(imageFile, fit: BoxFit.cover)
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 30, color: Colors.grey),
                        Text('Kliknij, aby dodać')
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zostań Kierowcą')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'Imię'),
                          validator: (v) => v!.isEmpty ? 'Wymagane' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Nazwisko'),
                          validator: (v) => v!.isEmpty ? 'Wymagane' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Adres e-mail'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.isEmpty || !v.contains('@') ? 'Podaj poprawny e-mail' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _carColorController,
                          decoration: const InputDecoration(labelText: 'Kolor auta'),
                          validator: (v) => v!.isEmpty ? 'Wymagane' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _carPlateController,
                          decoration: const InputDecoration(labelText: 'Rejestracja'),
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => v!.isEmpty ? 'Wymagane' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildImagePickerBox('Zdjęcie samochodu', _carPhotoFile, PhotoType.car),
                  _buildImagePickerBox('Dowód osobisty / Paszport', _idDocumentPhotoFile, PhotoType.idDocument),
                  _buildImagePickerBox('Wypis z licencji taksówkarskiej', _taxiLicensePhotoFile, PhotoType.taxiLicense),
                  _buildImagePickerBox('Prawo jazdy', _driverLicensePhotoFile, PhotoType.driverLicense),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _submitApplication,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text(
                      'Wyślij aplikację', 
                      style: TextStyle(fontSize: 16, color: Colors.white)
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }
}