import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_app_imakes/screen/coustomer_TrackingPage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});

  @override
  State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Position? _currentPosition;
  GoogleMapController? _mapController;

  String _userName = "Delivery User";
  String _userEmail = "";
  String? _activeOrderId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getCurrentLocation();
    _startLocationUpdates();
  }

  Future<void> _loadUserData() async {
    if (currentUser != null) {
      var doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userName = doc["name"] ?? "Delivery User";
          _userEmail = currentUser!.email ?? "";
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission permanently denied"),
          ),
        );
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _currentPosition = pos);

      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(currentUser!.uid)
            .update({
              "latitude": pos.latitude,
              "longitude": pos.longitude,
              "lastUpdated": FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Location Error: $e")));
    }
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      setState(() => _currentPosition = pos);

      if (_activeOrderId != null) {
        FirebaseFirestore.instance
            .collection("orders")
            .doc(_activeOrderId)
            .update({
              "driverLat": pos.latitude,
              "driverLng": pos.longitude,
              "lastUpdated": FieldValue.serverTimestamp(),
            });
      }
    });
  }

  Future<void> _updateLocation() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
      return;
    }

    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.uid)
        .update({
          "latitude": _currentPosition!.latitude,
          "longitude": _currentPosition!.longitude,
        });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Location updated")));
  }

  Stream<QuerySnapshot> _getAvailableOrders() {
    return FirebaseFirestore.instance
        .collection("orders")
        .where("status", whereIn: ["pending", "Assigned to delivery"])
        .snapshots();
  }

  Future<void> _acceptOrder(String orderId) async {
    if (_activeOrderId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already have an active order")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("orders").doc(orderId).update({
      "deliveryUid": currentUser!.uid,
      "status": "Assigned to delivery",
      "driverLat": _currentPosition?.latitude,
      "driverLng": _currentPosition?.longitude,
    });

    setState(() => _activeOrderId = orderId);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Order assigned to you")));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerTrackingPage(orderId: orderId),
      ),
    );
  }

  // cehck the widget tree to avoid the crash
  void _showCustomerMap(double lat, double lng) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text("Customer Location")),
        body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(lat, lng),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: const MarkerId("customer"),
              position: LatLng(lat, lng),
              infoWindow: const InfoWindow(title: "Customer Location"),
            ),
          },
          onMapCreated: (controller) => _mapController = controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Dashboard"),
        backgroundColor: Colors.deepOrange,
      ),

      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_userName),
              accountEmail: Text(_userEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black, size: 40),
              ),
              decoration: const BoxDecoration(color: Colors.deepOrange),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text("Update Location"),
              trailing: ElevatedButton(
                onPressed: _updateLocation,
                child: const Text("Update"),
              ),
            ),

            if (_activeOrderId != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text("Track Current Order"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CustomerTrackingPage(orderId: _activeOrderId!),
                      ),
                    );
                  },
                ),
              ),

            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Available Orders",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: _getAvailableOrders(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No available orders right now."),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(data["foodName"] ?? "Unknown Food"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Hotel: ${data["hotelName"] ?? "N/A"}"),
                            Text("Qty: ${data["quantity"] ?? 0}"),
                            Text(
                              "Customer: ${data["deliveryName"] ?? "Unknown"}",
                            ),
                            Text("Status: ${data["status"] ?? "N/A"}"),
                            Text("Amount: ₹${data["totalAmount"] ?? 0}"),
                            const SizedBox(height: 4),
                            if (data["imageUrl"] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data["imageUrl"],
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: data["status"] == "pending"
                              ? () => _acceptOrder(doc.id)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: data["status"] == "pending"
                                ? Colors.deepOrange
                                : Colors.grey,
                          ),
                          child: Text(
                            data["status"] == "pending" ? "Accept" : "Assigned",
                          ),
                        ),
                        onTap: () {
                          if (data["userLat"] != null &&
                              data["userLng"] != null) {
                            _showCustomerMap(data["userLat"], data["userLng"]);
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
