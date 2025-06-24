import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/api_config.dart';

class DriverIdVerificationScreen extends StatefulWidget {
  const DriverIdVerificationScreen({super.key});

  @override
  State<DriverIdVerificationScreen> createState() =>
      _DriverIdVerificationScreenState();
}

class _DriverIdVerificationScreenState
    extends State<DriverIdVerificationScreen> {
  bool idUploaded = false;
  bool licenseUploaded = false;
  bool submitted = false;

  File? uploadedIdFile;
  File? uploadedLicenseFile;

  String? idDocumentUrl;
  String? idDocumentMime;
  String? licenseDocumentUrl;
  String? licenseDocumentMime;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchUploadedDocuments();
  }

  Future<void> _fetchUploadedDocuments() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/driver/documents'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = Map<String, dynamic>.from(jsonDecode(response.body));
      setState(() {
        idDocumentUrl = data['id_document_url'];
        idDocumentMime = lookupMimeType(idDocumentUrl ?? '');
        licenseDocumentUrl = data['license_document_url'];
        licenseDocumentMime = lookupMimeType(licenseDocumentUrl ?? '');
        submitted = data['submitted'] ?? false;
        idUploaded = idDocumentUrl != null;
        licenseUploaded = licenseDocumentUrl != null;
      });
    }
  }

  Future<File?> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<void> _uploadDocument(String type) async {
    final file = await _pickImage();
    if (file == null) return;

    final mimeType = lookupMimeType(file.path);
    if (mimeType == null ||
        !['image/jpeg', 'image/png', 'application/pdf'].contains(mimeType)) {
      _showSnackBar('Unsupported file type. Only JPG, PNG, and PDF allowed.');
      return;
    }

    final token = await storage.read(key: 'token');
    if (token == null) {
      _showSnackBar('Authentication required');
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/driver/upload-document'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['type'] = type
      ..files.add(await http.MultipartFile.fromPath(
        'document',
        file.path,
        filename: p.basename(file.path),
      ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      setState(() {
        if (type == 'id') {
          idUploaded = true;
          uploadedIdFile = file;
          idDocumentUrl = null;
          idDocumentMime = mimeType;
        } else {
          licenseUploaded = true;
          uploadedLicenseFile = file;
          licenseDocumentUrl = null;
          licenseDocumentMime = mimeType;
        }
      });
      _showSnackBar('$type uploaded successfully');
    } else {
      debugPrint('Upload failed: ${response.statusCode} | $responseBody');
      _showSnackBar('Failed to upload $type');
    }
  }

  Future<void> _submitVerification() async {
    final token = await storage.read(key: 'token');
    if (token == null) {
      _showSnackBar('Authentication required');
      return;
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/driver/submit-verification'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        submitted = true;
      });
      _showSnackBar('Verification submitted for review.');
    } else {
      debugPrint('Submit failed: ${response.statusCode} ${response.body}');
      _showSnackBar('Failed to submit verification.');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showFullImage(String imagePath) {
    final imageProvider = imagePath.startsWith('http')
        ? NetworkImage(imagePath)
        : FileImage(File(imagePath)) as ImageProvider;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Center(child: Image(image: imageProvider)),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required bool uploaded,
    required VoidCallback onUpload,
    required File? localFile,
    required String? remoteUrl,
    required String? mimeType,
  }) {
    final isImage = mimeType?.startsWith('image/') ?? false;
    final isPdf = mimeType == 'application/pdf';

    Widget previewWidget = const Icon(Icons.insert_drive_file, size: 40);

    if (localFile != null && isImage) {
      previewWidget = Image.file(
        localFile, 
        width: 60, 
        height: 60, 
        fit: BoxFit.cover,
      );
    } else if (remoteUrl != null && isImage) {
        previewWidget = Image.network(
          'http://192.168.108.88:8000/storage/driver_documents/5/id.jpg',
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          // errorBuilder: (context, error, stackTrace) {
          //   debugPrint('Failed to load image preview: $remoteUrl');
          //   return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
          // },
        );
      } else if (isPdf) {
      previewWidget = const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: GestureDetector(
          onTap: isImage && (localFile != null || remoteUrl != null)
              ? () => _showFullImage(localFile?.path ?? remoteUrl!)
              : null,
          child: SizedBox(
            width: 60,
            height: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: previewWidget,
            ),
          ),
        ),
        title: Text(title),
        subtitle: uploaded
            ? Text(localFile?.path != null
                ? p.basename(localFile!.path)
                : (remoteUrl != null ? p.basename(remoteUrl) : ''))
            : const Text('No file uploaded'),
        trailing: submitted
            ? const Icon(Icons.lock, color: Colors.grey)
            : ElevatedButton.icon(
                icon: Icon(uploaded ? Icons.edit : Icons.upload_file),
                label: Text(uploaded ? 'Replace' : 'Upload'),
                onPressed: onUpload,
              ),
        onTap: !isImage && remoteUrl != null
            ? () => launchUrl(Uri.parse(remoteUrl), mode: LaunchMode.externalApplication)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver ID Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (submitted)
              Card(
                color: Colors.blue.shade50,
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.info, color: Colors.blue),
                  title: const Text('Documents submitted'),
                  subtitle:
                      const Text('Your documents are under review for verification.'),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Please upload the following documents:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildDocumentCard(
              title: 'Government-issued ID',
              uploaded: idUploaded,
              onUpload: () => _uploadDocument('id'),
              localFile: uploadedIdFile,
              remoteUrl: idDocumentUrl,
              mimeType: idDocumentMime,
            ),
            _buildDocumentCard(
              title: 'Driver\'s License',
              uploaded: licenseUploaded,
              onUpload: () => _uploadDocument('license'),
              localFile: uploadedLicenseFile,
              remoteUrl: licenseDocumentUrl,
              mimeType: licenseDocumentMime,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: idUploaded && licenseUploaded && !submitted
                  ? _submitVerification
                  : null,
              icon: const Icon(Icons.verified_user),
              label: const Text('Submit for Review'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}