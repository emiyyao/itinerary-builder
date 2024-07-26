import 'package:flutter/material.dart';
import 'package:finalproj/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalproj/trip_detail.dart';
import 'package:finalproj/profile_page.dart'; // Import the profile page
import 'package:intl/intl.dart'; // Import the intl package
import 'package:finalproj/share_trip.dart';


class HomeScreen extends StatelessWidget {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final auth = AuthService();
  final user = FirebaseAuth.instance.currentUser;

  void _viewTripDetails(BuildContext context, DocumentSnapshot trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripDetailsPage(trip: trip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore Your Trips'),
        actions: [
          TextButton(
            onPressed: () async {
              await auth.signout();
            },
            child: Text("Sign Out"),
          )
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('trips').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          var trips = snapshot.data?.docs;

          var userTrips = trips?.where((trip) {
            // Check if the trip belongs to the current user
            if (trip['uid'] == user?.uid) {
              print("Im here");
              return true;
            }
            if (trip['shared_users'] != null && trip['shared_users'].contains(user?.uid)) {
              print("Im here 2");
              return true;
            }
            return false;
          }).toList();

          userTrips?.sort((a, b) {
            DateTime aEndDate = dateFormat.parse(a['end_date']);
            DateTime bEndDate = dateFormat.parse(b['end_date']);

            // If both trips have passed their end dates, sort by start date
            if (aEndDate.isBefore(DateTime.now()) && bEndDate.isBefore(DateTime.now())) {
              DateTime aStartDate = dateFormat.parse(a['start_date']);
              DateTime bStartDate = dateFormat.parse(b['start_date']);
              return aStartDate.isBefore(bStartDate) ? -1 : 1;
            }

            // If one trip has passed its end date and the other hasn't, the one that has passed comes after
            if (aEndDate.isBefore(DateTime.now())) {
              return 1;
            }
            if (bEndDate.isBefore(DateTime.now())) {
              return -1;
            }

            // Otherwise, sort by end date (ascending)
            return aEndDate.isBefore(bEndDate) ? -1 : 1;
          });

          return ListView.builder(
            itemCount: userTrips?.length,
            itemBuilder: (context, index) {
              var trip = userTrips?[index];
              return ListTile(
                title: Text(trip?['location']),
                subtitle: Text('${trip?['start_date']} to ${trip?['end_date']}'),
                onTap: () => _viewTripDetails(context, trip as DocumentSnapshot<Object?>),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _editTrip(context, trip as DocumentSnapshot<Object?>),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteItem(trip as DocumentSnapshot<Object?>),
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ShareTripScreen(trip: trip as DocumentSnapshot<Object?>)),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTripDialog(context),
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTripDialog(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    final initialDate = DateTime.now();
    final firstDate = initialDate.subtract(Duration(days: 365));
    final lastDate = initialDate.add(Duration(days: 365));
    final tripDuration = Duration(days: 1); // Minimum duration for the trip (1 day)

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateController,
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                        ),
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final selectedDateRange = await showDateRangePicker(
                          context: context,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          initialDateRange: DateTimeRange(
                            start: initialDate,
                            end: initialDate.add(tripDuration),
                          ),
                        );
                        if (selectedDateRange != null) {
                          _startDateController.text =
                              dateFormat.format(selectedDateRange.start);
                          _endDateController.text =
                              dateFormat.format(selectedDateRange.end);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _endDateController,
                        decoration: InputDecoration(
                          labelText: 'End Date',
                        ),
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final selectedDateRange = await showDateRangePicker(
                          context: context,
                          firstDate: firstDate,
                          lastDate: lastDate,
                          initialDateRange: DateTimeRange(
                            start: initialDate,
                            end: initialDate.add(tripDuration),
                          ),
                        );
                        if (selectedDateRange != null) {
                          _startDateController.text =
                              dateFormat.format(selectedDateRange.start);
                          _endDateController.text =
                              dateFormat.format(selectedDateRange.end);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addTrip(context);
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addTrip(BuildContext context) {
    FirebaseFirestore.instance.collection('trips').add({
      'location': _locationController.text,
      'start_date': _startDateController.text,
      'end_date': _endDateController.text,
      'uid': user?.uid,
      'shared_users': [user?.uid]
    });
    _locationController.clear();
    _startDateController.clear();
    _endDateController.clear();
  }

  void _editTrip(BuildContext context, DocumentSnapshot trip) {
    final dateFormat = DateFormat.yMMMMd();
    final TextEditingController _editLocationController =
    TextEditingController(text: trip['location']);
    final TextEditingController _editStartDateController =
    TextEditingController(text: trip['start_date']);
    final TextEditingController _editEndDateController =
    TextEditingController(text: trip['end_date']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _editLocationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _editStartDateController,
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                        ),
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: dateFormat.parse(trip['start_date']),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          _editStartDateController.text =
                              dateFormat.format(selectedDate);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _editEndDateController,
                        decoration: InputDecoration(
                          labelText: 'End Date',
                        ),
                        readOnly: true,
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: dateFormat.parse(trip['end_date']),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDate != null) {
                          _editEndDateController.text =
                              dateFormat.format(selectedDate);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                trip.reference.update({
                  'location': _editLocationController.text,
                  'start_date': _editStartDateController.text,
                  'end_date': _editEndDateController.text,
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }


  void _deleteItem(DocumentSnapshot item) {
    item.reference.delete();
  }
}
