import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TripMap extends StatefulWidget {
  final List<Marker> markers;
  final String tripName;

  TripMap({required this.markers, required this.tripName});

  @override
  _TripMapState createState() => _TripMapState();
}

class _TripMapState extends State<TripMap> {
  late GoogleMapController _controller;

  void _fitMarkersToBounds(GoogleMapController controller) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (Marker marker in widget.markers) {
      double lat = marker.position.latitude;
      double lng = marker.position.longitude;
      minLat = min(lat, minLat);
      maxLat = max(lat, maxLat);
      minLng = min(lng, minLng);
      maxLng = max(lng, maxLng);
    }

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100); // 100 is padding
    controller.animateCamera(cameraUpdate);
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    LatLng centerPosition = _calculateCenterPosition(); // Calculate center position
    CameraPosition initialCameraPosition = CameraPosition(
      target: centerPosition,
      zoom: 10.0,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tripName),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
          _fitMarkersToBounds(_controller);
        },
        markers: Set<Marker>.of(widget.markers),
        initialCameraPosition: initialCameraPosition,
      ),
    );
  }

  LatLng _calculateCenterPosition() {
    double totalLat = 0.0;
    double totalLng = 0.0;
    for (Marker marker in widget.markers) {
      totalLat += marker.position.latitude;
      totalLng += marker.position.longitude;
    }
    double centerLat = totalLat / widget.markers.length;
    double centerLng = totalLng / widget.markers.length;
    return LatLng(centerLat, centerLng);
  }
}