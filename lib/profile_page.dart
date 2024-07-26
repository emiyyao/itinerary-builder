import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _displayNameController = TextEditingController();
  User? _user = FirebaseAuth.instance.currentUser;
  String _displayName = '';
  String _photoURL = '';

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    DocumentSnapshot userInfo =
    await _firestore.collection('users').doc(_user!.uid).get();
    setState(() {
      _photoURL = userInfo['photoURL'] ?? '';
      _displayName = userInfo['displayName'] ?? '';
      _displayNameController.text = _displayName;
    });
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String fileName = _user!.uid + '_profile.jpg'; // Unique filename
      firebase_storage.Reference ref =
      firebase_storage.FirebaseStorage.instance.ref().child('profile_images').child(fileName);
      await ref.putFile(file);
      String imageUrl = await ref.getDownloadURL();
      await _firestore.collection('users').doc(_user!.uid).update({
        'photoURL': imageUrl,
      });
      setState(() {
        _photoURL = imageUrl;
      });
    }
  }

  Future<void> _updateDisplayName(String newName) async {
    await _firestore.collection('users').doc(_user!.uid).update({
      'displayName': newName,
    });
    setState(() {
      _displayName = newName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage: _photoURL.isNotEmpty
                  ? NetworkImage(_photoURL)
                  : NetworkImage(
                  "https://www.google.com/url?sa=i&url=https%3A%2F%2Fpixabay.com%2Fvectors%2Fblank-profile-picture-mystery-man-973460%2F&psig=AOvVaw35TnTw3epODmpW5TNq_Xn4&ust=1713630057935000&source=images&cd=vfe&opi=89978449&ved=0CBIQjRxqFwoTCOj4jMnXzoUDFQAAAAAdAAAAABAE"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _uploadImage();
              },
              child: Text('Upload Profile Image'),
            ),
            SizedBox(height: 20),
            Text(
              'Display Name: $_displayName',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _updateDisplayName(_displayNameController.text);
              },
              child: Text('Save Display Name'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }
}
