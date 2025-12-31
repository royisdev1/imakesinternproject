import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to view your orders.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("userId", isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading orders."));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final order = doc.data() as Map<String, dynamic>;

              final foodName = order["foodName"] ?? "Unknown item";
              final quantity = order["quantity"] ?? 1;
              final totalAmount = order["totalAmount"] ?? "--";
              final status = order["status"] ?? "Pending";
              final imageUrl = order["imageUrl"] ?? "";

              // ✅ Delivery fields
              final deliveryUid = order["deliveryUid"] ?? "Not assigned";
              final userLat = order["userLat"];
              final userLng = order["userLng"];
              final driverLat = order["driverLat"];
              final driverLng = order["driverLng"];

              // Handle timestamp safely
              String orderTime = "";
              if (order["orderAt"] != null && order["orderAt"] is Timestamp) {
                orderTime = (order["orderAt"] as Timestamp)
                    .toDate()
                    .toString()
                    .substring(0, 16);
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.receipt_long, color: Colors.blue),
                  title: Text(foodName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Quantity: $quantity"),
                      Text("Total: ₹$totalAmount"),
                      Text("Status: $status"),
                      const SizedBox(height: 6),

                      if (status == "assigned") ...[
                        Text(
                          "Assigned to: $deliveryUid",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.deepOrange,
                          ),
                        ),
                        Text("Customer Location: $userLat , $userLng"),
                        if (driverLat != null && driverLng != null)
                          Text("Driver Live: $driverLat , $driverLng"),
                        if (driverLat == null || driverLng == null)
                          const Text(
                            "Driver has not started yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ],
                  ),
                  trailing: Text(
                    orderTime,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
