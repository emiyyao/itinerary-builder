import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShareTripScreen extends StatefulWidget {
  final DocumentSnapshot trip;

  ShareTripScreen({required this.trip});

  @override
  _ShareTripScreenState createState() => _ShareTripScreenState();
}

class _ShareTripScreenState extends State<ShareTripScreen> {
  late List<String> sharedUsers = []; // Initialize as late
  late String currentUserID; // Initialize as late

  @override
  void initState() {
    super.initState();
    // Fetch current user's ID
    currentUserID = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Initialize sharedUsers list by retrieving data from Firestore
    FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .get()
        .then((tripSnapshot) {
      if (tripSnapshot.exists) {
        setState(() {
          // Retrieve shared users from the trip document
          sharedUsers = List<String>.from(tripSnapshot['shared_users'] ?? []);
        });
      } else {
        // If the trip document doesn't exist or doesn't have shared_users field,
        // initialize an empty list
        sharedUsers = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share Trip'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          var users = snapshot.data?.docs;
          // Exclude current user from the list of users
          var filteredUsers = users?.where((user) => user.id != currentUserID).toList();
          return ListView.builder(
            itemCount: filteredUsers?.length,
            itemBuilder: (context, index) {
              var user = filteredUsers?[index];
              return CheckboxListTile(
                title: Text(user?['displayName']),
                value: sharedUsers.contains(user?.id), // Check if user is shared
                onChanged: (value) {
                  setState(() {
                    if (value!) {
                      // Add user to sharedUsers list
                      sharedUsers.add(user!.id);
                    } else {
                      // Remove user from sharedUsers list
                      sharedUsers.remove(user?.id);
                    }
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Update shared status in Firestore
          FirebaseFirestore.instance.collection('trips').doc(widget.trip.id).update({
            'shared_users': sharedUsers,
          });
          Navigator.pop(context);
        },
        child: Icon(Icons.save),
      ),
    );
  }
}
