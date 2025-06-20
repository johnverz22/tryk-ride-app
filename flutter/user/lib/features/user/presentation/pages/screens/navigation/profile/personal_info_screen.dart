import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/user_provider.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context).user;
    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber;
      _dobController.text = user.lastLoginAt?.toIso8601String().split("T").first ?? "1990-01-01";
      _locationController.text = user.location ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // _buildEditableField("Full Name", _nameController),
            _buildEditableField("Email Address", _emailController),
            // _buildEditableField("Phone Number", _phoneController),
            // _buildEditableField("Date of Birth", _dobController),
            // _buildEditableField("Location", _locationController),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_formKey.currentState!.validate() && user != null) {
                  final updatedUser = user.copyWith(
                    // fullName: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                    // phoneNumber: _phoneController.text.trim(),
                    // location: _locationController.text.trim(),
                    updatedAt: DateTime.now(),
                  );

                  try {
                    await userProvider.updateUser(updatedUser);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Changes saved")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Update failed: $e")),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w500),
          suffixIcon: const Icon(Icons.edit_outlined, size: 20),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
