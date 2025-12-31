import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'foodDetail.dart';

class HotelMenuScreen extends StatelessWidget {
  final String hotelUid;
  final String hotelName;

  const HotelMenuScreen({
    super.key,
    required this.hotelUid,
    required this.hotelName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hotelName), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tables
            const Text(
              "🪑 Tables",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("tables")
                  .where("ownerUid", isEqualTo: hotelUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No tables available.");
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.table_bar,
                          color: Colors.brown,
                        ),
                        title: Text(
                          "Table No: ${data["tableNumber"] ?? "N/A"}",
                        ),
                        subtitle: Text("Seats: ${data["capacity"] ?? "N/A"}"),
                        trailing: Text(
                          data["status"] ?? "Available",
                          style: TextStyle(
                            color: (data["status"] == "Available")
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // food items
            const Text(
              "🍲 Menu Items",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("foodItems")
                  .where("ownerUid", isEqualTo: hotelUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No food items available.");
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FoodDetailPage(foodId: doc.id),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CachedNetworkImage(
                            imageUrl:
                                data["imageUrl"] ??
                                "https://via.placeholder.com/150",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          title: Text(data["name"] ?? "Unnamed Dish"),
                          subtitle: Text("Price: ₹${data["price"] ?? "N/A"}"),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // offers
            const Text(
              "🔥 Offers",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("offers")
                  .where("ownerUid", isEqualTo: hotelUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No offers available.");
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CachedNetworkImage(
                          imageUrl:
                              data["imageUrl"] ??
                              "https://via.placeholder.com/150",
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        title: Text(data["title"] ?? "Offer"),
                        subtitle: Text(data["description"] ?? ""),
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
