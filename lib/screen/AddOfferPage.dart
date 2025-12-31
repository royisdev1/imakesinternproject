import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  final foodNameController = TextEditingController();
  final originalRateController = TextEditingController();
  final offerPriceController = TextEditingController();
  final ratingController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final imageUrlController = TextEditingController();

  bool loading = false;
  bool useUrl = false;
  File? selectedImage;

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
        "offer_images/${DateTime.now().millisecondsSinceEpoch}.jpg",
      );
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
      return null;
    }
  }

  Future<void> saveOffer() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    if (foodNameController.text.isEmpty ||
        originalRateController.text.isEmpty ||
        offerPriceController.text.isEmpty ||
        ratingController.text.isEmpty ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        (!useUrl && selectedImage == null) ||
        (useUrl && imageUrlController.text.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => loading = true);

    try {
      // use to fetch hotel details of owner
      var hotelSnapshot = await FirebaseFirestore.instance
          .collection("hotels")
          .where("ownerUid", isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (hotelSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No hotel details found for this owner"),
          ),
        );
        setState(() => loading = false);
        return;
      }

      var hotelDoc = hotelSnapshot.docs.first;
      var hotelData = hotelDoc.data();
      String hotelId = hotelDoc.id;

      // get the final image url
      String? finalImageUrl;
      if (useUrl) {
        finalImageUrl = imageUrlController.text.trim();
      } else {
        finalImageUrl = await uploadImage(selectedImage!);
        if (finalImageUrl == null) {
          setState(() => loading = false);
          return;
        }
      }

      // its use for unique id geranartion
      String offerId = FirebaseFirestore.instance.collection("offers").doc().id;

      // file save formate
      await FirebaseFirestore.instance.collection("offers").doc(offerId).set({
        "offerId": offerId,
        "foodName": foodNameController.text.trim(),
        "originalRate": double.parse(originalRateController.text.trim()),
        "offerPrice": double.parse(offerPriceController.text.trim()),
        "rating": double.parse(ratingController.text.trim()),
        "date": dateController.text.trim(),
        "time": timeController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
        "ownerUid": currentUser.uid,
        "hotelId": hotelId,
        "hotelName": hotelData["hotelName"] ?? "",
        "ownerMobile": hotelData["mobile"] ?? "",
        "ownerName": hotelData["ownerName"] ?? "",
        "lat": hotelData["lat"], // 🔥 latitude from hotel
        "lng": hotelData["lng"], // 🔥 longitude from hotel
        "imageUrl": finalImageUrl,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Offer added successfully")));

      foodNameController.clear();
      originalRateController.clear();
      offerPriceController.clear();
      ratingController.clear();
      dateController.clear();
      timeController.clear();
      imageUrlController.clear();
      selectedImage = null;
      setState(() => useUrl = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Offers"),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: foodNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Food Name",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: originalRateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Original Rate",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: offerPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Offer Price",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ratingController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Rating (out of 5)",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Date",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Time",
              ),
            ),
            const SizedBox(height: 20),

            //image unput method
            SwitchListTile(
              value: useUrl,
              onChanged: (val) {
                setState(() {
                  useUrl = val;
                  selectedImage = null;
                });
              },
              title: const Text("Use Google Image URL"),
            ),

            if (useUrl)
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Paste Image URL",
                ),
              )
            else
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: selectedImage == null
                      ? const Center(child: Text("Tap to select image"))
                      : Image.file(selectedImage!, fit: BoxFit.cover),
                ),
              ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : saveOffer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Offer"),
            ),
          ],
        ),
      ),
    );
  }
}
