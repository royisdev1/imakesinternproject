import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  Future<String?> getOwnerHotelId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    final hotelSnap = await FirebaseFirestore.instance
        .collection("hotels")
        .where("ownerUid", isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (hotelSnap.docs.isNotEmpty) {
      return hotelSnap.docs.first.id;
    }
    return null;
  }

  Stream<QuerySnapshot> getMyOrders(String hotelId) {
    return FirebaseFirestore.instance
        .collection("orders")
        .where("hotelId", isEqualTo: hotelId)
        .snapshots();
  }

  Future<void> assignDelivery(BuildContext context, String orderId) async {
    final deliveryUsers = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "delivery")
        .get();

    if (deliveryUsers.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No delivery users available")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: deliveryUsers.docs.map((doc) {
            var data = doc.data();
            return ListTile(
              leading: const Icon(
                Icons.delivery_dining,
                color: Colors.deepOrange,
              ),
              title: Text(data["name"] ?? "Unknown"),
              subtitle: Text(data["email"] ?? ""),
              onTap: () async {
                await FirebaseFirestore.instance
                    .collection("orders")
                    .doc(orderId)
                    .update({
                      "deliveryUid": doc.id,
                      "deliveryName": data["name"] ?? "",
                      "deliveryEmail": data["email"] ?? "",
                      "status": "Assigned to delivery",
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Order assigned to ${data["name"] ?? "Delivery"}",
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
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
      body: FutureBuilder<String?>(
        future: getOwnerHotelId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text("No hotel found for current owner"),
            );
          }

          final hotelId = snapshot.data!;
          return StreamBuilder<QuerySnapshot>(
            stream: getMyOrders(hotelId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No orders found for your hotel"),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(12),
                children: snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Food image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: data["imageUrl"] != null
                              ? Image.network(
                                  data["imageUrl"],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.fastfood, size: 50),
                                )
                              : const Icon(Icons.fastfood, size: 50),
                        ),
                        const SizedBox(width: 12),
                        // Food details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data["foodName"] ?? "Unknown",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Qty: ${data["quantity"]} | User: ${data["userId"] ?? "N/A"}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Status: ${data["status"] ?? "Pending"}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      data["status"] == "Assigned to delivery"
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "₹${data["totalAmount"] ?? 0}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Assign delivery button to the available delivery users
                        ElevatedButton(
                          onPressed: () => assignDelivery(context, doc.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text("Assign Delivery"),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
