import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditFoodItemPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;

  const EditFoodItemPage({
    super.key,
    required this.docId,
    required this.currentData,
  });

  @override
  State<EditFoodItemPage> createState() => _EditFoodItemPageState();
}

class _EditFoodItemPageState extends State<EditFoodItemPage> {
  late TextEditingController foodNameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;

  File? newFoodImage;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    foodNameController = TextEditingController(
      text: widget.currentData["name"],
    );
    priceController = TextEditingController(
      text: widget.currentData["price"].toString(),
    );
    descriptionController = TextEditingController(
      text: widget.currentData["description"],
    );
  }

  Future<void> pickNewImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() {
        newFoodImage = File(pickedFile.path);
      });
    }
  }

  Future<void> saveChanges() async {
    if (foodNameController.text.isEmpty ||
        priceController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => loading = true);

    try {
      String imageUrl = widget.currentData["imageUrl"];

      if (newFoodImage != null) {
        String fileName = "food_${DateTime.now().millisecondsSinceEpoch}.jpg";
        Reference ref = FirebaseStorage.instance
            .ref()
            .child("foodImages")
            .child(fileName);

        UploadTask uploadTask = ref.putFile(
          newFoodImage!,
          SettableMetadata(contentType: "image/jpeg"),
        );
        TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection("menuItems")
          .doc(widget.docId)
          .update({
            "name": foodNameController.text.trim(),
            "price": double.parse(priceController.text.trim()),
            "description": descriptionController.text.trim(),
            "imageUrl": imageUrl,
            "updatedAt": FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Food item updated successfully")),
      );

      Navigator.pop(context);
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
        title: const Text("Eadit food ITEM"),
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

            // image preview and change button
            Center(
              child: newFoodImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        newFoodImage!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                  : widget.currentData["imageUrl"] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.currentData["imageUrl"],
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Text("📷 No image"),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: pickNewImage,
                icon: const Icon(Icons.image),
                label: const Text("Change Image"),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: loading ? null : saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
