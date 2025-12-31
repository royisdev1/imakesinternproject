import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddFoodItemPage extends StatefulWidget {
  final dynamic hotelId;

  const AddFoodItemPage({super.key, required this.hotelId});

  @override
  State<AddFoodItemPage> createState() => _AddFoodItemPageState();
}

class _AddFoodItemPageState extends State<AddFoodItemPage> {
  final foodNameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();
  final tagsController = TextEditingController();

  File? foodImage;
  bool loading = false;
  String? finalImageUrl;
  bool isVeg = true;

  String? hotelId; // it use to fetch

  @override
  void initState() {
    super.initState();
    fetchHotelId();
  }

  Future<void> fetchHotelId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("hotels")
        .where("ownerUid", isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        hotelId = snapshot.docs.first.id;
      });
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() {
        foodImage = File(pickedFile.path);
        finalImageUrl = null;
        imageUrlController.clear();
      });
    }
  }

  Future<void> uploadFoodItem() async {
    if (hotelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No hotel found for this owner")),
      );
      return;
    }

    if (foodNameController.text.isEmpty ||
        priceController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        (foodImage == null && imageUrlController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠ Please fill all fields & provide an image"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ You must be logged in")),
        );
        setState(() => loading = false);
        return;
      }

      // use to image save
      if (foodImage != null) {
        String fileName = "food_${DateTime.now().millisecondsSinceEpoch}.jpg";
        Reference ref = FirebaseStorage.instance
            .ref()
            .child("foodImages")
            .child(fileName);

        UploadTask uploadTask = ref.putFile(
          foodImage!,
          SettableMetadata(contentType: "image/jpeg"),
        );

        TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        finalImageUrl = await snapshot.ref.getDownloadURL();
      } else if (imageUrlController.text.isNotEmpty) {
        finalImageUrl = imageUrlController.text.trim();
      }

      List<String> tags = tagsController.text
          .split(",")
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // its for save in fire store
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection("menuItems")
          .add({
            "ownerUid": currentUser.uid,
            "hotelId": hotelId,
            "name": foodNameController.text.trim(),
            "price": double.parse(priceController.text.trim()),
            "description": descriptionController.text.trim(),
            "imageUrl": finalImageUrl,
            "isVeg": isVeg,
            "tags": tags,
            "createdAt": FieldValue.serverTimestamp(),
          });

      await docRef.update({"foodId": docRef.id});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Food item added successfully")),
      );

      // clear
      foodNameController.clear();
      priceController.clear();
      descriptionController.clear();
      imageUrlController.clear();
      tagsController.clear();
      setState(() {
        foodImage = null;
        finalImageUrl = null;
        isVeg = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Food"),
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
      body: hotelId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Price",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Description",
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Text("Type:"),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text("Veg"),
                        selected: isVeg,
                        onSelected: (val) {
                          setState(() => isVeg = true);
                        },
                        selectedColor: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text("Non-Veg"),
                        selected: !isVeg,
                        onSelected: (val) {
                          setState(() => isVeg = false);
                        },
                        selectedColor: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // tags
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Tags (comma separated)",
                      hintText: "e.g., Curry, Spicy, Paneer",
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    "Image Options",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Image URL (optional)",
                      hintText: "Paste image URL here",
                    ),
                    onChanged: (value) {
                      setState(() {
                        finalImageUrl = value.trim();
                        if (value.isNotEmpty) foodImage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Center(child: Text("OR")),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text("Pick Image from Device"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: finalImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              finalImageUrl!,
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        : foodImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              foodImage!,
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Text("📷 No image selected"),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: loading ? null : uploadFoodItem,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("➕ Add Food Item"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
