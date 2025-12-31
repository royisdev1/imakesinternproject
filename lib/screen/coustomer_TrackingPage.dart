import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class CustomerTrackingPage extends StatefulWidget {
  final String orderId;

  const CustomerTrackingPage({super.key, required this.orderId});

  @override
  State<CustomerTrackingPage> createState() => _CustomerTrackingPageState();
}

class _CustomerTrackingPageState extends State<CustomerTrackingPage> {
  GoogleMapController? _mapController;
  Marker? _driverMarker;
  Marker? _customerMarker;

  double? _customerLat;
  double? _customerLng;

  bool _isCameraMoved = false;
  LatLng? _lastDriverPos;

  @override
  void initState() {
    super.initState();
    _loadCustomerLocation();
  }

  Future<void> _loadCustomerLocation() async {
    final doc = await FirebaseFirestore.instance
        .collection("orders")
        .doc(widget.orderId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        setState(() {
          _customerLat = (data["userLat"] as num?)?.toDouble();
          _customerLng = (data["userLng"] as num?)?.toDouble();
        });
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose(); // it use in use for memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Your Delivery"),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found ⚠️"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("No tracking data available"));
          }

          final double? driverLat = (data["driverLat"] as num?)?.toDouble();
          final double? driverLng = (data["driverLng"] as num?)?.toDouble();

          if (_customerLat == null || _customerLng == null) {
            return const Center(
              child: Text("Customer location not available ❌"),
            );
          }

          if (driverLat == null || driverLng == null) {
            return const Center(child: Text("Waiting for driver to start 🚚"));
          }

          LatLng driverPos = LatLng(driverLat, driverLng);
          LatLng customerPos = LatLng(_customerLat!, _customerLng!);

          _driverMarker = Marker(
            markerId: const MarkerId("driver"),
            position: driverPos,
            infoWindow: const InfoWindow(title: "Driver"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          );

          _customerMarker = Marker(
            markerId: const MarkerId("customer"),
            position: customerPos,
            infoWindow: const InfoWindow(title: "You"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          );

          if (_mapController != null && !_isCameraMoved) {
            LatLngBounds bounds = LatLngBounds(
              southwest: LatLng(
                driverLat < _customerLat! ? driverLat : _customerLat!,
                driverLng < _customerLng! ? driverLng : _customerLng!,
              ),
              northeast: LatLng(
                driverLat > _customerLat! ? driverLat : _customerLat!,
                driverLng > _customerLng! ? driverLng : _customerLng!,
              ),
            );

            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 100),
            );
            _isCameraMoved = true;
          }

          if (_mapController != null && _lastDriverPos != null) {
            final distance = Geolocator.distanceBetween(
              _lastDriverPos!.latitude,
              _lastDriverPos!.longitude,
              driverPos.latitude,
              driverPos.longitude,
            );

            if (distance > 50) {
              _mapController!.animateCamera(CameraUpdate.newLatLng(driverPos));
              _lastDriverPos = driverPos;
            }
          } else {
            _lastDriverPos = driverPos;
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: customerPos,
              zoom: 14,
            ),
            markers: {
              if (_driverMarker != null) _driverMarker!,
              if (_customerMarker != null) _customerMarker!,
            },
            onMapCreated: (controller) {
              _mapController = controller;
            },
            liteModeEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
          );
        },
      ),
    );
  }
}
