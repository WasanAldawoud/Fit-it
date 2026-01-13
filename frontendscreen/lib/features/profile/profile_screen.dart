import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontendscreen/features/home_page/home_page.dart';
import 'package:frontendscreen/features/plan_creation/presentation/screens/create_plan_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontendscreen/app_styles/color_constants.dart';

import 'dart:convert'; // Used to turn JSON from the server into Dart Maps
import 'package:http/http.dart' as http; // Main library for API calls
import 'package:http/browser_client.dart'; // Handles Cookies for Web (Passport.js support)
import 'package:flutter/foundation.dart'; // Used for kIsWeb checks

/// A screen that manages the user's profile data by communicating with the Node.js backend.
class ProfileScreen extends StatefulWidget {
  final String? userName;
  final String? gender;
  final DateTime? birthDate;
  final double? weight;
  final double? height;

  const ProfileScreen({
    Key? key,
    this.userName,
    this.gender,
    this.birthDate,
    this.weight,
    this.height,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- UI State Variables ---
  bool isEditing = false;
  bool isLoading = true; // Shows a spinner while fetching data from the DB

  // --- Profile Data Variables ---
  String? userName;
  String? gender;
  DateTime? birthDate;
  String? photoPath;
  Uint8List? webImage; 
  double? weight;
  double? height;

  // --- Form Controllers ---
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    
    // Automatically fetch the latest data from the PostgreSQL DB when the screen opens
    fetchUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // ==========================================
  // BACKEND COMMUNICATION LOGIC
  // ==========================================

  /// Helper to get the correct Base URL based on whether you are on Web, Emulator, or Device.
  String _getBaseUrl() {
    if (kIsWeb) return 'http://localhost:3000/auth/profile';
    if (Platform.isAndroid) return 'http://26.35.223.225:3000/auth/profile';
    return 'http://10.0.2.2:3000/auth/profile';
  }

  /// GET Request: Downloads user data from the Node.js /profile route.
  Future<void> fetchUserProfile() async {
    try {
      var client = http.Client();
      
      // If Web, we MUST use BrowserClient to ensure the session cookie is sent
      if (kIsWeb) client = BrowserClient()..withCredentials = true;

      final response = await client.get(
        Uri.parse(_getBaseUrl()),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        // Parse the JSON object returned by your 'getProfile' controller
        final userData = jsonDecode(response.body)['user'];
        
        setState(() {
          userName = userData['username'];
          
          // Basic formatting to ensure the gender matches our Dropdown values
          if (userData['gender'] != null) {
            String g = userData['gender'].toString().toLowerCase();
            gender = g[0].toUpperCase() + g.substring(1);
          } else {
            gender = 'Other';
          }

          if (userData['birthdate'] != null) birthDate = DateTime.parse(userData['birthdate']);
          
          weight = double.tryParse(userData['weight'].toString());
          height = double.tryParse(userData['height'].toString());

          // Populate the text fields with the fetched data
          _nameController.text = userName ?? '';
          _weightController.text = weight?.toString() ?? '';
          _heightController.text = height?.toString() ?? '';
          
          isLoading = false; // Data loaded, hide the spinner
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Error fetching profile: $e");
      setState(() => isLoading = false);
    }
  }

  /// PUT Request: Uploads edited profile data back to the PostgreSQL database.
  Future<void> updateUserProfile() async {
    try {
      var client = http.Client();
      if (kIsWeb) client = BrowserClient()..withCredentials = true;

      // Send the updated data as a JSON body to the backend
      final response = await client.put(
        Uri.parse(_getBaseUrl()), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _nameController.text,
          "gender": gender,
          "birthdate": birthDate?.toIso8601String(), // Send dates in ISO format
          "weight": double.tryParse(_weightController.text) ?? 0,
          "height": double.tryParse(_heightController.text) ?? 0,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated successfully!')),
        );
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving changes')),
      );
    }
  }

  // ==========================================
  // UI COMPONENTS
  // ==========================================

  @override
  Widget build(BuildContext context) {
    // Show a loading circle while the GET request is in progress
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: ColorConstants.primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: ColorConstants.primaryColor,
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: _toggleEdit,
            child: Text(
              isEditing ? 'Save' : 'Edit',
              style: const TextStyle(color: ColorConstants.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(),
          const SizedBox(height: 20),
          _genderSection(),
          _birthDateSection(),
          _heightWeightSection(),
          const Divider(),
          _actionTile(Icons.home, 'Home Page', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()));
          }),
          _actionTile(Icons.star, 'Your Plan', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePlanScreen()));
          }),
          _actionTile(Icons.help_outline, 'Get Help', () => _showSimpleDialog('git')),
          _actionTile(Icons.info_outline, 'About App', () => _showSimpleDialog('about')),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor, 
        borderRadius: BorderRadius.circular(16)
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: isEditing ? _pickImage : null,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              backgroundImage: _getProfileImage(),
              child: _getProfileImage() == null 
                  ? const Icon(Icons.person, size: 55, color: ColorConstants.primaryColor) 
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            enabled: isEditing,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ColorConstants.white),
            decoration: const InputDecoration(
              hintText: 'Enter your username',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (kIsWeb && webImage != null) return MemoryImage(webImage!);
    if (!kIsWeb && photoPath != null) return FileImage(File(photoPath!));
    return null; 
  }

  Widget _genderSection() {
    return ListTile(
      title: const Text('Gender'),
      trailing: DropdownButton<String>(
        value: (gender == 'Male' || gender == 'Female' || gender == 'Other') ? gender : 'Other',
        onChanged: isEditing ? (v) => setState(() => gender = v) : null,
        items: ['Female', 'Male', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      ),
    );
  }

  Widget _birthDateSection() {
    return ListTile(
      leading: const Icon(Icons.cake, color: ColorConstants.primaryColor),
      title: const Text('Birthdate'),
      subtitle: Text(birthDate == null ? 'Select birthdate' : '${birthDate!.day}/${birthDate!.month}/${birthDate!.year}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: isEditing ? _pickBirthDate : null,
    );
  }

  Widget _heightWeightSection() {
    return Column(
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _weightController,
          enabled: isEditing,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _heightController,
          enabled: isEditing,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: ColorConstants.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _toggleEdit() {
    if (isEditing) {
      // If we are currently in editing mode and click Save, call the PUT request
      updateUserProfile();
    }
    setState(() => isEditing = !isEditing);
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() { webImage = bytes; photoPath = image.path; });
      } else {
        setState(() => photoPath = image.path);
      }
    }
  }

  void _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2003),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => birthDate = date);
  }

  void _showSimpleDialog(String type) {
    final color = ColorConstants.accentColor;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type == 'git' ? Icons.help_outline : Icons.info_outline, size: 50, color: color),
              const SizedBox(height: 12),
              Text(type == 'git' ? 'Get Help' : 'About App', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 10),
              Text(type == 'git' ? 'For help contact us at email@example.com' : 'Fitness App', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}