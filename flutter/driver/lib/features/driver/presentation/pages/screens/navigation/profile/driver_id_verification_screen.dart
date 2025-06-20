import 'package:flutter/material.dart';

class DriverIdVerificationScreen extends StatefulWidget {
  const DriverIdVerificationScreen({super.key});

  @override
  State<DriverIdVerificationScreen> createState() => _DriverIdVerificationScreenState();
}

class _DriverIdVerificationScreenState extends State<DriverIdVerificationScreen> {
  bool idUploaded = false;
  bool licenseUploaded = false;
  bool submitted = false;

  void _uploadDocument(String type) {
    setState(() {
      if (type == 'id') idUploaded = true;
      if (type == 'license') licenseUploaded = true;
    });
  }

  void _submitVerification() {
    if (idUploaded && licenseUploaded) {
      setState(() {
        submitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification submitted for review.')),
      );
    }
  }

  Widget _buildUploadTile(String label, bool uploaded, VoidCallback onPressed) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(
        uploaded ? Icons.check_circle : Icons.upload_file,
        color: uploaded ? Colors.green : Colors.grey,
      ),
      title: Text(label),
      trailing: ElevatedButton(
        onPressed: onPressed,
        child: Text(uploaded ? 'Uploaded' : 'Upload'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload the following documents to verify your driver account:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildUploadTile('Government-issued ID', idUploaded, () => _uploadDocument('id')),
            const SizedBox(height: 12),
            _buildUploadTile('Driver\'s License', licenseUploaded, () => _uploadDocument('license')),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: idUploaded && licenseUploaded && !submitted ? _submitVerification : null,
              icon: const Icon(Icons.verified_user),
              label: const Text('Submit for Review'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
