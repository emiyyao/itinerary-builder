
import 'package:finalproj/trip_map.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';


class TripDetailsPage extends StatefulWidget {
  final DocumentSnapshot trip;

  TripDetailsPage({required this.trip});

  @override
  _TripDetailsPageState createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  List<Marker> _markers = [];
  late List<DateTime> _days;
  final picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _photoURL = '';

  @override
  void initState() {
    super.initState();
    _generateDays();
    _getThumbnail();
    _fetchMarkers();
  }

  Future<void> _getThumbnail() async {
    DocumentSnapshot thumbnail =
    await _firestore.collection('thumbnails').doc(widget.trip.id).get();
    setState(() {
      _photoURL = thumbnail['photoURL'] ?? '';
    });
  }

  void _generateDays() {
    DateTime startDate = _parseDate(widget.trip['start_date']);
    DateTime endDate = _parseDate(widget.trip['end_date']);

    _days = [];
    for (DateTime day = startDate; day.isBefore(endDate) || day.isAtSameMomentAs(endDate); day = day.add(const Duration(days: 1))) {
      _days.add(day);
    }
  }

  // Method to fetch markers from Firestore
  void _fetchMarkers() async {
    QuerySnapshot<Map<String, dynamic>> markerSnapshot = await FirebaseFirestore.instance
        .collection('trip_items')
        .where('trip_id', isEqualTo: widget.trip.id)
        .get();

    setState(() {
      _markers = markerSnapshot.docs.map((DocumentSnapshot document) {
        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
        LatLng position = LatLng(data['latitude'], data['longitude']);
        return Marker(
          markerId: MarkerId(document.id),
          position: position,
          infoWindow: InfoWindow(title: data['name']),
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('Trip Details'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    child: _photoURL.isNotEmpty
                        ? CircleAvatar(
                      radius: 100,
                      backgroundImage: _photoURL.isNotEmpty
                          ? NetworkImage(_photoURL)
                          : NetworkImage(
                          "https://www.google.com/url?sa=i&url=https%3A%2F%2Fpixabay.com%2Fvectors%2Fblank-profile-picture-mystery-man-973460%2F&psig=AOvVaw35TnTw3epODmpW5TNq_Xn4&ust=1713630057935000&source=images&cd=vfe&opi=89978449&ved=0CBIQjRxqFwoTCOj4jMnXzoUDFQAAAAAdAAAAABAE"),
                    )
                        : Placeholder(
                      fallbackHeight: MediaQuery.of(context).size.width,
                      color: Colors.grey,
                    ),
                  ),
                  if (_photoURL.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: _showImageSourceOptions,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: _deleteImage,
                          ),
                        ],
                      ),
                    ),
                  if (_photoURL.isEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: FloatingActionButton(
                        onPressed: _showImageSourceOptions,
                        tooltip: 'Add Image',
                        child: Icon(Icons.add_a_photo),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.trip['location']}',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${widget.trip['start_date']} to ${widget.trip['end_date']}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final day = _days[index];
                return ExpansionTile(
                  title: Text(
                    _formatDate(day),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    _buildActivitiesList(day),
                    _buildSearchBar(day),
                  ],
                );
              },
              childCount: _days.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripMap(tripName: '${widget.trip['location']}', markers: _markers)),
          );
        },
        child: const Icon(Icons.map),
      ),
    );
  }

  Future<void> _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      File _imagetwo = File(pickedFile.path);
      String fileName = '${widget.trip.id}_thumbnail.jpg'; // Unique filename
      firebase_storage.Reference ref =
      firebase_storage.FirebaseStorage.instance.ref().child('thumbnail_images').child(fileName);
      await ref.putFile(_imagetwo);
      String imageUrl = await ref.getDownloadURL();
      await _firestore.collection('thumbnails').doc(widget.trip.id).set({
        'photoURL': imageUrl,
      });
      setState(() {
        _photoURL = imageUrl;
      });
    }
  }

  void _deleteImage() {
    setState(() {
      _photoURL = "";
    });
  }

  Widget _buildActivitiesList(DateTime day) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('trip_items')
          .where('trip_id', isEqualTo: widget.trip.id)
          .where('date', isEqualTo: _formatDate(day))
          .orderBy('timestamp', descending: true) // Order items by timestamp in descending order
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading data'),
          );
        }
        final items = snapshot.data?.docs ?? []; // Use null-aware operators to handle null values
        return ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final itemName = item['name'] as String? ?? ''; // Handle null values for item name
            print('${item['name']} WAS MADE AT ${item['timestamp']}');
            return ListTile(
              title: Text(itemName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _showEditItemDialog(context, item as DocumentSnapshot<Object?>),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteItem(item as DocumentSnapshot<Object?>),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar(DateTime day) {
    TextEditingController controller = TextEditingController(text: 'Add a location');
    bool isInitialText = true;
    double? lat = 0;
    double? lng = 0;
    LatLng pos = LatLng(lat, lng);
    // Listen for changes in the text field value
    controller.addListener(() {
      // Check if the initial text is being displayed and the user starts typing
      if (isInitialText && controller.text != 'Add a location') {
        // Clear the initial text
        controller.clear();
        isInitialText = false;
      }
    });
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: GooglePlaceAutoCompleteTextField(
      textEditingController: controller,
      googleAPIKey: "InsertAPIKeyHere",
      inputDecoration: InputDecoration(),
      debounceTime: 800, // default 600 ms,
      isLatLngRequired:true,// if you required coordinates from place detail
      getPlaceDetailWithLatLng: (Prediction prediction) {
        // this method will return latlng with place detail
        print("placeDetails: ${prediction.lat}, ${prediction.lng}");
        if(prediction.lat != null){
          lat = double.tryParse(prediction.lat.toString());
          print("Lat to double: ${lat}");
        }
        if(prediction.lng != null){
          lng = double.tryParse(prediction.lng.toString());
          print("Lng to double: ${lng}");
        }
        pos = LatLng(lat!, lng!);
        print("${pos.latitude}, ${pos.longitude}");
        _addItem(context, day, prediction.description ?? '', pos);
      }, // this callback is called when isLatLngRequired is true
      itemClick: (Prediction prediction) {
        controller.text=prediction.description!;
        controller.selection = TextSelection.fromPosition(TextPosition(offset: prediction.description!.length));
        controller.clear();
      },
      // if we want to make custom list item builder
      itemBuilder: (context, index, Prediction prediction) {
        return Container(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(Icons.location_on),
              SizedBox(
                width: 7,
              ),
              Expanded(child: Text("${prediction.description??""}"))
            ],
          ),
        );
      },
      // if you want to add seperator between list items
      seperatedBuilder: Divider(),
      // want to show close icon
      isCrossBtnShown: true,
      // optional container padding
      containerHorizontalPadding: 10,)
        );
  }

  void _addItem(BuildContext context, DateTime? day, String name, LatLng position) {
    FirebaseFirestore.instance.collection('trip_items').add({
      'trip_id': widget.trip.id,
      'name': name,
      'date': day != null ? _formatDate(day) : 'No Date',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch, // Add timestamp for sorting
    }).then((DocumentReference document) {
      // Add marker to the map
      Marker marker = Marker(
        markerId: MarkerId(document.id),
        position: position,
        infoWindow: InfoWindow(title: name),
      );
      setState(() {
        _markers.add(marker);
        print("MARKERS ADDED: ${position.latitude}, ${position.longitude}");
      });
    });
    // print("ITEM ADDED AT ${DateTime.now().millisecondsSinceEpoch}");
  }

  void _showEditItemDialog(BuildContext context, DocumentSnapshot item) {
    TextEditingController _itemNameController =
    TextEditingController(text: item['name']);
    double? lat = 0;
    double? lng = 0;
    LatLng pos = LatLng(lat, lng);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GooglePlaceAutoCompleteTextField(
                textEditingController: _itemNameController,
                googleAPIKey: "AIzaSyAHXqFevxzZXDotQDX0U5iGY7z8AKgm_60",
                debounceTime: 800,
                isLatLngRequired:true,// if you required coordinates from place detail
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  // this method will return latlng with place detail
                  print("placeDetails: ${prediction.lat}, ${prediction.lng}");
                  if(prediction.lat != null){
                    lat = double.tryParse(prediction.lat.toString());
                    print("Lat to double: ${lat}");
                  }
                  if(prediction.lng != null){
                    lng = double.tryParse(prediction.lng.toString());
                    print("Lng to double: ${lng}");
                  }
                  pos = LatLng(lat!, lng!);
                  print("${pos.latitude}, ${pos.longitude}");
                }, // this callback is called when isLatLngRequired is true
                itemClick: (Prediction prediction) {
                  _itemNameController.text=prediction.description!;
                  _itemNameController.selection = TextSelection.fromPosition(TextPosition(offset: prediction.description!.length));
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _editItem(context, item, _itemNameController.text, pos);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _editItem(BuildContext context, DocumentSnapshot item, String name, LatLng position) {
    item.reference.update({
      'name': name,
      'latitude': position.latitude,
      'longitude': position.longitude,
    });
    Marker? markerToUpdate = _markers.firstWhere((marker) => marker.markerId.value == item.id);
    if (markerToUpdate != null) {
      setState(() {
        _markers.remove(markerToUpdate);
        _markers.add(Marker(
          markerId: MarkerId(item.id),
          position: position,
          infoWindow: InfoWindow(title: name),
        ));
        print("MARKERS EDITED TO: ${position.latitude}, ${position.longitude}");
      });
    }
  }

  void _deleteItem(DocumentSnapshot item) {
    _markers.removeWhere((marker) => marker.markerId.value == item.id);
    item.reference.delete();
  }

  String _formatDate(DateTime date) {
    return DateFormat('E, MMM d').format(date);
  }

  DateTime _parseDate(String dateString) {
    return DateFormat.yMMMMd().parse(dateString);
  }
}
