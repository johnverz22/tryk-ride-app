// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:intl/intl.dart';
// import '../../../../widgets/widgets.dart';
// import '../../../../providers/driver_provider.dart';

// class PersonalInfoScreen extends ConsumerStatefulWidget {
//   const PersonalInfoScreen({super.key});

//   @override
//   ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
// }

// class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _scrollController = ScrollController();

//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _dobController = TextEditingController();
//   final _locationController = TextEditingController();
//   DateTime? _selectedDate;
//   bool _hasChanges = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final user = ref.read(driverProvider).value?.driver;
//       if (user != null) {
//         _nameController.text = user.name;
//         _emailController.text = user.email;
//         _phoneController.text = user.phone;
//         _selectedDate = user.lastLoginAt ?? DateTime(1990, 1, 1);
//         _dobController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
//         _locationController.text = user.location ?? "";
//       }
//       _setupChangeListeners();
//     });
//   }

//   void _setupChangeListeners() {
//     for (final ctrl in [
//       _nameController,
//       _emailController,
//       _phoneController,
//       _locationController,
//       _dobController,
//     ]) {
//       ctrl.addListener(() {
//         setState(() => _hasChanges = true);
//       });
//     }
//   }

//   bool get isSaveEnabled =>
//       _hasChanges && (_formKey.currentState?.validate() ?? false);

//   @override
//   Widget build(BuildContext context) {
//     const SizedBox sectionSpacing = SizedBox(height: 24);

//     return PopScope(
//       canPop: !_hasChanges,
//       onPopInvokedWithResult: (bool didPop, Object? result) async {
//         if (didPop || !_hasChanges) return;

//         final shouldDiscard = await showDialog<bool>(
//           context: context,
//           builder: (ctx) => AlertDialog(
//             title: const Text('Discard changes?'),
//             content: const Text(
//               'You have unsaved edits. Do you want to discard them?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(ctx).pop(false),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(ctx).pop(true),
//                 child: const Text('Discard'),
//               ),
//             ],
//           ),
//         );

//         if (shouldDiscard == true && context.mounted) {
//           Navigator.of(context).pop();
//         }
//       },
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         appBar: AppBar(
//           title: const Text('Personal Information'),
//           centerTitle: true,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () async {
//               if (!_hasChanges) {
//                 Navigator.pop(context);
//                 return;
//               }

//               final shouldDiscard = await showDialog<bool>(
//                 context: context,
//                 builder: (ctx) => AlertDialog(
//                   title: const Text('Discard changes?'),
//                   content: const Text(
//                     'You have unsaved edits. Do you want to discard them?',
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.of(ctx).pop(false),
//                       child: const Text('Cancel'),
//                     ),
//                     TextButton(
//                       onPressed: () => Navigator.of(ctx).pop(true),
//                       child: const Text('Discard'),
//                     ),
//                   ],
//                 ),
//               );

//               if (shouldDiscard == true && context.mounted) {
//                 Navigator.of(context).pop();
//               }
//             },
//           ),
//         ),
//         body: ref
//             .watch(userProvider)
//             .when(
//               loading: () => const Center(child: CircularProgressIndicator()),
//               error: (e, _) => Center(child: Text('Error: $e')),
//               data: (state) {
//                 final user = state?.user;
//                 if (user == null) {
//                   return const Center(child: Text("User not found"));
//                 }

//                 return Form(
//                   key: _formKey,
//                   autovalidateMode: AutovalidateMode.onUserInteraction,
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
//                     controller: _scrollController,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _sectionTitle('Basic Info'),
//                         _buildField('Full Name', Icons.person, _nameController),
//                         _buildField(
//                           'Date of Birth',
//                           Icons.cake,
//                           _dobController,
//                           readOnly: true,
//                           onTap: _pickDate,
//                         ),
//                         sectionSpacing,
//                         _sectionTitle('Contact Info'),
//                         _buildField(
//                           'Email Address',
//                           Icons.email,
//                           _emailController,
//                           type: TextInputType.emailAddress,
//                         ),
//                         _buildField(
//                           'Phone Number',
//                           Icons.phone,
//                           _phoneController,
//                           type: TextInputType.phone,
//                         ),
//                         sectionSpacing,
//                         _sectionTitle('Location'),
//                         _buildField(
//                           'City / Country',
//                           Icons.location_on,
//                           _locationController,
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//         bottomSheet: SaveChangesButton(
//           isEnabled: isSaveEnabled,
//           onPressed: _handleSave,
//           label: 'Save Changes',
//           icon: Icons.save,
//         ),
//       ),
//     );
//   }

//   Widget _sectionTitle(String text) => Padding(
//     padding: const EdgeInsets.only(bottom: 8),
//     child: Text(
//       text,
//       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
//     ),
//   );

//   Widget _buildField(
//     String label,
//     IconData icon,
//     TextEditingController ctrl, {
//     TextInputType type = TextInputType.text,
//     bool readOnly = false,
//     VoidCallback? onTap,
//   }) {
//     final theme = Theme.of(context);
//     final fillColor = theme.brightness == Brightness.dark
//         ? Colors.grey.shade900
//         : Colors.grey.shade100;

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Focus(
//         child: Builder(
//           builder: (context) {
//             final isFocused = Focus.of(context).hasFocus;

//             return AnimatedContainer(
//               duration: const Duration(milliseconds: 250),
//               curve: Curves.easeInOut,
//               decoration: BoxDecoration(
//                 color: fillColor,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: isFocused
//                     ? [
//                         BoxShadow(
//                           color: theme.colorScheme.primary.withValues(
//                             alpha: 0.25,
//                           ),
//                           blurRadius: 10,
//                           offset: const Offset(0, 4),
//                         ),
//                       ]
//                     : [],
//               ),
//               child: TextFormField(
//                 controller: ctrl,
//                 keyboardType: type,
//                 textInputAction: TextInputAction.next,
//                 readOnly: readOnly,
//                 onTap: onTap,
//                 decoration: InputDecoration(
//                   labelText: label,
//                   labelStyle: TextStyle(
//                     color: isFocused
//                         ? theme.colorScheme.primary
//                         : theme.textTheme.bodyLarge?.color,
//                   ),
//                   prefixIcon: Icon(
//                     icon,
//                     color: isFocused
//                         ? theme.colorScheme.primary
//                         : theme.iconTheme.color,
//                   ),
//                   suffixIcon: readOnly
//                       ? Icon(
//                           Icons.calendar_today,
//                           color: isFocused
//                               ? theme.colorScheme.primary
//                               : theme.iconTheme.color,
//                         )
//                       : Icon(
//                           Icons.edit,
//                           color: isFocused
//                               ? theme.colorScheme.primary
//                               : theme.iconTheme.color,
//                         ),
//                   filled: true,
//                   fillColor: Colors.transparent,
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: Colors.grey.shade400,
//                       width: 1,
//                     ),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: theme.colorScheme.primary,
//                       width: 2,
//                     ),
//                   ),
//                   errorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: theme.colorScheme.error,
//                       width: 1.5,
//                     ),
//                   ),
//                   focusedErrorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: theme.colorScheme.error,
//                       width: 2,
//                     ),
//                   ),
//                 ),
//                 validator: (v) {
//                   final value = v?.trim() ?? '';
//                   if (value.isEmpty) return 'Please enter $label';
//                   if (label.contains('Email') &&
//                       !RegExp(
//                         r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,4}$',
//                       ).hasMatch(value)) {
//                     return 'Invalid email';
//                   }
//                   if (label.contains('Phone') &&
//                       !RegExp(r'^[\d +()-]{7,15}$').hasMatch(value)) {
//                     return 'Invalid phone';
//                   }
//                   return null;
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Future<void> _pickDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate ?? DateTime(1990),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         _selectedDate = picked;
//         _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
//         _hasChanges = true;
//       });
//     }
//   }

//   Future<void> _handleSave() async {
//     final user = ref.read(userProvider).value?.user;
//     if (user == null) return;
//     if (_formKey.currentState?.validate() != true) {
//       Scrollable.ensureVisible(
//         _formKey.currentContext!,
//         duration: const Duration(milliseconds: 300),
//       );
//       return;
//     }

//     final updatedUser = user.copyWith(
//       name: _nameController.text.trim(),
//       email: _emailController.text.trim(),
//       phone: _phoneController.text.trim(),
//       location: _locationController.text.trim(),
//       lastLoginAt: _selectedDate,
//       updatedAt: DateTime.now(),
//     );

//     try {
//       await ref.read(userProvider.notifier).updateUser(updatedUser);
//       setState(() => _hasChanges = false);
//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//         ..clearSnackBars()
//         ..showSnackBar(
//           const SnackBar(
//             content: Text('Changes saved successfully'),
//             behavior: SnackBarBehavior.floating,
//             duration: Duration(seconds: 2),
//           ),
//         );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _dobController.dispose();
//     _locationController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
// }
