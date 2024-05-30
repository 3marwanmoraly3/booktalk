import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:booktalk/utils.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  String _username = '';
  String _avatarUrl = '';

  File? _avatarImage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    String? userId =
        await getUserId(); // Get the user's ID from shared preferences
    if (userId != null) {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection('User').doc(userId).get();

      if (snapshot.exists) {
        setState(() {
          _avatarUrl = snapshot.get('AvatarUrl');
          _username = snapshot.get('Username');
          _usernameController.text = _username;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
        _uploadAvatar(); // Call the _uploadAvatar function
      });
    }
  }

  Future<void> _uploadAvatar() async {
    if (_avatarImage != null) {
      String? userId =
          await getUserId(); // Get the user's ID from shared preferences
      if (userId != null) {
        String fileName = '${userId}_avatar.jpg';
        Reference storageRef =
            FirebaseStorage.instance.ref().child('avatars/$fileName');

        await storageRef.putFile(_avatarImage!);
        String avatarUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('User')
            .doc(userId)
            .update({'AvatarUrl': avatarUrl});

        setState(() {
          _avatarUrl = avatarUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully')),
        );
      }
    }
  }

  Future<void> _changeUsername() async {
    String? userId =
        await getUserId();

    String newUsername = _usernameController.text.trim();

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('User')
        .where('Username', isEqualTo: newUsername)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username already exists')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('User')
          .doc(userId)
          .update({'Username': newUsername});

      setState(() {
        _username = newUsername;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
    } catch (e) {
      print('Error updating username: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update username')),
      );
    }
  }

  Future<void> _changePassword() async {
    String? userId =
        await getUserId();

    String currentPassword = _currentPasswordController.text;
    String newPassword = _newPasswordController.text;
    String confirmNewPassword = _confirmNewPasswordController.text;

    if (newPassword != confirmNewPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    try {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection('User').doc(userId).get();

      if (snapshot.exists) {
        String storedPasswordHash = snapshot.get('Password');
        String currentPasswordHash =
            sha256.convert(utf8.encode(currentPassword)).toString();

        if (storedPasswordHash != currentPasswordHash) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Current password is incorrect')),
          );
          return;
        }

        String newPasswordHash =
            sha256.convert(utf8.encode(newPassword)).toString();
        await FirebaseFirestore.instance
            .collection('User')
            .doc(userId)
            .update({'Password': newPasswordHash});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
      } else {
        print('User document does not exist');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to change password')),
        );
      }
    } catch (e) {
      print('Error changing password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xffDCE9FF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Account',
            style: TextStyle(
                color: Color(0xff6255FA),
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xffDCE9FF),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Color(0xff6255FA),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: Color(0xffDCE9FF),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Stack(children: [
                  CircleAvatar(
                    radius: 60.0,
                    backgroundImage: _avatarImage != null
                        ? FileImage(_avatarImage!) as ImageProvider
                        : _avatarUrl.isNotEmpty
                            ? NetworkImage(_avatarUrl)
                            : const AssetImage(
                                    'assets/images/default_avatar.png')
                                as ImageProvider,
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      radius: 60,
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _usernameController,
                  style: TextStyle(fontSize: 22),
                  decoration: InputDecoration(
                    hintText: 'Username',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                    width: 250,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _changeUsername,
                      child: const Text(
                        'Change Username',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Color(0xff6255FA),
                      ),
                    )),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _currentPasswordController,
                  style: TextStyle(fontSize: 22),
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'Current Password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _newPasswordController,
                  style: TextStyle(fontSize: 22),
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _confirmNewPasswordController,
                  style: TextStyle(fontSize: 22),
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'Confrim New Password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: 250,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    child: const Text(
                      'Change Password',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Color(0xff6255FA),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
