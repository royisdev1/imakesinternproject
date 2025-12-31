import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_app_imakes/screen/AddHotelDetailsPage.dart';
import 'package:food_app_imakes/screen/MyFoodItemsPage.dart';
import 'package:food_app_imakes/screen/add_food_item_page.dart';
import 'package:food_app_imakes/screen/TableCountPage.dart';
import 'package:food_app_imakes/screen/AddOfferPage.dart';
import 'package:food_app_imakes/screen/MyOrdersPage.dart';
import 'package:food_app_imakes/screen/settings.dart';

class HotelOwnerHomePage extends StatefulWidget {
  const HotelOwnerHomePage({super.key});

  @override
  State<HotelOwnerHomePage> createState() => _HotelOwnerHomePageState();
}

class _HotelOwnerHomePageState extends State<HotelOwnerHomePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? hotelId;

  Stream<QuerySnapshot> getOrdersStream() {
    return FirebaseFirestore.instance
        .collection("orders")
        .where("ownerUid", isEqualTo: currentUser?.uid)
        .snapshots();
  }

  /// Fetch owner details from both users & hotelDetails collections
  Future<Map<String, dynamic>?> _getOwnerDetails() async {
    if (currentUser == null) return null;

    // First check in "users" collection
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser!.uid)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      return userDoc.data();
    }

    // Fallback → fetch from "hotels" collection
    final hotelDoc = await FirebaseFirestore.instance
        .collection("hotels")
        .where("ownerUid", isEqualTo: currentUser!.uid)
        .limit(1)
        .get();

    if (hotelDoc.docs.isNotEmpty) {
      final data = hotelDoc.docs.first.data();
      hotelId = data["hotelId"]; // ✅ capture hotelId
      return data;
    }

    return null;
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

  Widget glassyCard({required Widget child, double width = 200}) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double headerHeight = MediaQuery.of(context).size.height * 0.18;

    return Scaffold(
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange, Colors.redAccent], // same as header
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _getOwnerDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ownerData = snapshot.data;
                final ownerName =
                    ownerData?["name"] ??
                    ownerData?["hotelName"] ??
                    "Hotel Owner";
                final ownerEmail = currentUser?.email ?? "No Email";
                final ownerImage = ownerData?["imageUrl"];

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    UserAccountsDrawerHeader(
                      decoration: const BoxDecoration(
                        color: Colors.transparent, // keep gradient visible
                      ),
                      accountName: Text(
                        ownerName,
                        style: const TextStyle(
                          color: Colors.white,

                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      accountEmail: Text(
                        ownerEmail,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: ownerImage != null
                            ? NetworkImage(ownerImage)
                            : null,
                        child: ownerImage == null
                            ? const Icon(
                                Icons.store,
                                color: Colors.deepOrange,
                                size: 30,
                              )
                            : null,
                      ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.white),
                      title: const Text(
                        "Add New Food Item",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddFoodItemPage(hotelId: hotelId),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.list, color: Colors.white),
                      title: const Text(
                        "View My Food Items",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyFoodItemsPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.store, color: Colors.white),
                      title: const Text(
                        "Add Hotel Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddHotelDetailsPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.table_chart,
                        color: Colors.white,
                      ),
                      title: const Text(
                        "Manage Table Count",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TableCountPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.local_offer,
                        color: Colors.white,
                      ),
                      title: const Text(
                        "Add New Offer",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OfferScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                      ),
                      title: const Text(
                        "View My Orders",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyOrdersPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.white),
                      title: const Text(
                        "Settings",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: headerHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange, Colors.redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Hamburger
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Hotel Owner Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // food Items
                  const Text(
                    "🍴 Food Items",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: currentUser == null
                        ? const Center(child: Text("Login to view food items."))
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("menuItems")
                                .where(
                                  "ownerUid",
                                  isEqualTo: currentUser!.uid,
                                ) // ✅ fixed
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text("No food items added yet."),
                                );
                              }
                              return ListView(
                                scrollDirection: Axis.horizontal,
                                children: snapshot.data!.docs.map((doc) {
                                  var data = doc.data() as Map<String, dynamic>;
                                  return glassyCard(
                                    width: 220,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (data["imageUrl"] != null)
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(20),
                                                  topRight: Radius.circular(20),
                                                ),
                                            child: Image.network(
                                              data["imageUrl"],
                                              height: 100,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data["name"] ?? "Unnamed",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                data["description"] ?? "",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                "₹${data["price"] ?? 0}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.deepOrange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),

                  // 🪑 Table Details
                  const Text(
                    "🪑 Table Details",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: currentUser == null
                        ? const Center(
                            child: Text("Login to view table details."),
                          )
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("tables")
                                .where(
                                  "ownerId",
                                  isEqualTo: currentUser!.uid,
                                ) // ✅ correct field
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text("No table details available."),
                                );
                              }

                              return ListView(
                                scrollDirection: Axis.horizontal,
                                children: snapshot.data!.docs.map((doc) {
                                  var data = doc.data() as Map<String, dynamic>;

                                  String tableName =
                                      data["tableName"] ?? "Unnamed";
                                  String url = data["url"] ?? "";
                                  String status =
                                      data["status"] ??
                                      "Unknown"; // ✅ add status
                                  String time =
                                      data["time"] ?? "N/A"; // ✅ add timing
                                  var createdAt = data["createdAt"];
                                  String date = createdAt != null
                                      ? (createdAt as Timestamp)
                                            .toDate()
                                            .toString()
                                            .split(" ")
                                            .first // just YYYY-MM-DD
                                      : "No Date";

                                  return glassyCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ✅ Table Image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            url,
                                            height: 80,
                                            width: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.table_bar,
                                                      size: 50,
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // ✅ Table Name
                                        Text(
                                          tableName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),

                                        // ✅ Status (Available / Booked)
                                        Text(
                                          "Status: $status",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),

                                        // ✅ Timing
                                        Text(
                                          "⏰ $time",
                                          style: const TextStyle(fontSize: 12),
                                        ),

                                        // ✅ Created Date
                                        Text(
                                          "📅 $date",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 16),

                  // 🎉 Active Offers
                  const Text(
                    "🎉 Active Offers",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180, // slightly taller to fit image + text
                    child: currentUser == null
                        ? const Center(child: Text("Login to view offers."))
                        : StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("offers")
                                .where("ownerUid", isEqualTo: currentUser!.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text("No active offers."),
                                );
                              }

                              return ListView(
                                scrollDirection: Axis.horizontal,
                                children: snapshot.data!.docs.map((doc) {
                                  var data = doc.data() as Map<String, dynamic>;

                                  return glassyCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // ✅ Show image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            data["imageUrl"] ?? "",
                                            height: 80,
                                            width: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.fastfood,
                                                      size: 50,
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // ✅ Food + Hotel Name
                                        Text(
                                          data["foodName"] ?? "Unnamed Offer",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          data["hotelName"] ?? "",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),

                                        // ✅ Offer Price & Original Price
                                        Text(
                                          "₹${data["offerPrice"]}  (MRP: ₹${data["originalRate"]})",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.green,
                                          ),
                                        ),

                                        // ✅ Offer Timing
                                        Text(
                                          "⏰ ${data["time"] ?? ''}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                  ),

                  // 📦 Orders
                  // 📦 Orders
                  const Text(
                    "📦 Recent Orders",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("orders")
                        .where("hotelId", isEqualTo: hotelId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text("No orders yet.");
                      }

                      return SizedBox(
                        height: 186, // fixed height for horizontal scrolling
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: snapshot.data!.docs.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            return glassyCard(
                              width: 220, // fixed width for each card
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SingleChildScrollView(
                                  // prevents vertical overflow
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Food image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: data["imageUrl"] != null
                                            ? Image.network(
                                                data["imageUrl"],
                                                width: double.infinity,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.fastfood,
                                                      size: 50,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.fastfood,
                                                size: 50,
                                              ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        data["foodName"] ?? "Unknown",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Qty: ${data["quantity"] ?? 0}\nUser: ${data["userEmail"] ?? "N/A"}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "₹${data["totalAmount"] ?? 0}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ElevatedButton(
                                        onPressed: () {
                                          assignDelivery(context, doc.id);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepOrange,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        child: const Text("Assign Delivery"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
