import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_app_imakes/services/location_service.dart';
import 'package:geocoding/geocoding.dart';

class AddHotelDetailsPage extends StatefulWidget {
  const AddHotelDetailsPage({super.key});

  @override
  State<AddHotelDetailsPage> createState() => _AddHotelDetailsPageState();
}

class _AddHotelDetailsPageState extends State<AddHotelDetailsPage> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final imageUrlController = TextEditingController();
  final cuisineController = TextEditingController(); // comma separated
  final ratingController = TextEditingController();

  bool loading = false;
  String? hotelDocId;
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    fetchHotelDetails();
  }

  Future<void> fetchHotelDetails() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => loading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection("hotels")
          .where("ownerUid", isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        hotelDocId = doc.id;

        final data = doc.data();
        nameController.text = data["name"] ?? "";
        addressController.text = data["address"] ?? "";
        phoneController.text = data["phone"] ?? "";
        imageUrlController.text = data["imageUrl"] ?? "";
        ratingController.text = (data["rating"] ?? "").toString();
        latitude = data["latitude"];
        longitude = data["longitude"];
        if (data["cuisineType"] != null) {
          cuisineController.text = (data["cuisineType"] as List<dynamic>)
              .map((e) => e.toString())
              .join(", ");
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading hotel details: $e")),
      );
    }

    setState(() => loading = false);
  }

  Future<void> pickLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
        });

        List<Placemark> placemarks = await placemarkFromCoordinates(
          latitude!,
          longitude!,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address =
              "${place.name}, ${place.locality}, ${place.subAdministrativeArea}, "
              "${place.administrativeArea}, ${place.country}";

          setState(() {
            addressController.text = address;
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Location updated: $address")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Location error: $e")));
    }
  }

  Future<void> saveHotelDetails() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (nameController.text.isEmpty ||
        addressController.text.isEmpty ||
        phoneController.text.isEmpty ||
        imageUrlController.text.isEmpty ||
        cuisineController.text.isEmpty ||
        ratingController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please add location")));
      return;
    }

    setState(() => loading = true);

    try {
      final hotelData = {
        "ownerUid": currentUser.uid,
        "name": nameController.text.trim(),
        "imageUrl": imageUrlController.text.trim(),
        "latitude": latitude,
        "longitude": longitude,
        "address": addressController.text.trim(),
        "phone": phoneController.text.trim(),
        "rating": double.tryParse(ratingController.text.trim()) ?? 0.0,
        "cuisineType": cuisineController.text
            .split(",")
            .map((e) => e.trim())
            .toList(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (hotelDocId != null) {
        // hotel updated
        await FirebaseFirestore.instance
            .collection("hotels")
            .doc(hotelDocId)
            .update({...hotelData, "hotelId": hotelDocId});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hotel details updated successfully")),
        );
      } else {
        // if the hotel is not existed it will created the new hotel
        final docRef = await FirebaseFirestore.instance
            .collection("hotels")
            .add({...hotelData, "createdAt": FieldValue.serverTimestamp()});

        hotelDocId = docRef.id;

        // use to add the hotels id
        await docRef.update({"hotelId": docRef.id});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hotel details added successfully")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  Future<void> deleteHotel() async {
    if (hotelDocId == null) return;

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection("hotels")
          .doc(hotelDocId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hotel deleted successfully")),
      );

      hotelDocId = null;
      nameController.clear();
      addressController.clear();
      phoneController.clear();
      imageUrlController.clear();
      cuisineController.clear();
      ratingController.clear();
      latitude = null;
      longitude = null;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting hotel: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hottel Deatails"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange, Colors.redAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Hotel Name",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Hotel Image URL",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Address",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Phone Number",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ratingController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Rating (0.0 - 5.0)",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cuisineController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Cuisine Types (comma separated)",
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          addressController.text.isNotEmpty
                              ? addressController.text
                              : (latitude != null && longitude != null
                                    ? "Lat: ${latitude!.toStringAsFixed(5)}, Lng: ${longitude!.toStringAsFixed(5)}"
                                    : "No location selected"),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: pickLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text("Add Location"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: loading ? null : saveHotelDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                hotelDocId != null
                                    ? "Update Hotel Details"
                                    : "Save Hotel Details",
                              ),
                      ),
                      if (hotelDocId != null)
                        ElevatedButton(
                          onPressed: loading ? null : deleteHotel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text("Delete"),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
