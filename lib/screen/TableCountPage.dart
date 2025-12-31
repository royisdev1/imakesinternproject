import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TableCountPage extends StatefulWidget {
  const TableCountPage({super.key});

  @override
  State<TableCountPage> createState() => _TableCountPageState();
}

class _TableCountPageState extends State<TableCountPage> {
  final tableCountController = TextEditingController();
  final urlController = TextEditingController();
  bool loading = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String? hotelId;
  String? lat;
  String? lng;

  @override
  void initState() {
    super.initState();
    _fetchHotelAndOwnerDetails();
  }

  Future<void> _fetchHotelAndOwnerDetails() async {
    if (currentUser == null) return;
    final hotelSnap = await FirebaseFirestore.instance
        .collection("hotels")
        .where("ownerUid", isEqualTo: currentUser!.uid)
        .limit(1)
        .get();

    if (hotelSnap.docs.isNotEmpty) {
      final hotelDoc = hotelSnap.docs.first;
      final data = hotelDoc.data();
      setState(() {
        hotelId = hotelDoc.id;
        lat = data.containsKey("lat") ? data["lat"].toString() : "0.0";
        lng = data.containsKey("lng") ? data["lng"].toString() : "0.0";
      });
    }
  }

  Future<void> addTables() async {
    if (hotelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No hotel found for this owner")),
      );
      return;
    }
    if (tableCountController.text.isEmpty || urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter table count and image URL")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      int tableCount = int.parse(tableCountController.text.trim());
      String imageUrl = urlController.text.trim();

      for (int i = 1; i <= tableCount; i++) {
        String tableId = FirebaseFirestore.instance
            .collection("tables")
            .doc()
            .id;

        await FirebaseFirestore.instance.collection("tables").doc(tableId).set({
          "tableId": tableId,
          "tableName": "Table $i",
          "description": "",
          "url": imageUrl,
          "ownerId": currentUser!.uid,
          "hotelId": hotelId,
          "lat": lat ?? "0.0",
          "lng": lng ?? "0.0",
          "seats": "4",
          "status": "available",
          "time": "", // default empty
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$tableCount tables created successfully")),
      );
      tableCountController.clear();
      urlController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
    setState(() => loading = false);
  }

  Stream<QuerySnapshot> getOwnerTables() {
    if (hotelId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection("tables")
        .where("hotelId", isEqualTo: hotelId)
        .where("ownerId", isEqualTo: currentUser!.uid)
        .snapshots();
  }

  /// Edit table with time slot
  void editTable(String docId, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data["tableName"] ?? "");
    final seatController = TextEditingController(text: data["seats"] ?? "4");
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();

    // Parse existing time if available
    if ((data["time"] ?? "").contains("-")) {
      List<String> times = data["time"].split("-");
      startTimeController.text = times[0].trim();
      endTimeController.text = times[1].trim();
    }

    String status = data["status"] ?? "available";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Table"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Table Name"),
              ),
              TextField(
                controller: seatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Seats"),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startTimeController,
                      decoration: const InputDecoration(
                        labelText: "Start Time",
                        hintText: "e.g. 12:00 PM",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: endTimeController,
                      decoration: const InputDecoration(
                        labelText: "End Time",
                        hintText: "e.g. 2:00 PM",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: "Status"),
                items: const [
                  DropdownMenuItem(
                    value: "available",
                    child: Text("Available"),
                  ),
                  DropdownMenuItem(value: "booked", child: Text("Booked")),
                ],
                onChanged: (val) {
                  if (val != null) status = val;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String timeSlot = "";
              if (startTimeController.text.isNotEmpty &&
                  endTimeController.text.isNotEmpty) {
                timeSlot =
                    "${startTimeController.text.trim()} - ${endTimeController.text.trim()}";
              }
              await FirebaseFirestore.instance
                  .collection("tables")
                  .doc(docId)
                  .update({
                    "tableName": nameController.text.trim(),
                    "seats": seatController.text.trim(),
                    "status": status,
                    "time": timeSlot,
                  });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("✅ Table updated successfully")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void deleteTable(String docId) async {
    bool confirm = false;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Table"),
        content: const Text("Are you sure you want to delete this table?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              confirm = true;
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm) {
      await FirebaseFirestore.instance.collection("tables").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Table deleted successfully")),
      );
    }
  }

  Widget glassyCard({required Widget child}) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Table Management"),
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
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tableCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Number of Tables",
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: urlController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Image URL",
                            hintText: "Enter table image URL",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: loading ? null : addTables,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("➕ Create Tables"),
                  ),
                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "🪑 Table Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: getOwnerTables(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError)
                          return Center(
                            child: Text("Error: ${snapshot.error}"),
                          );
                        if (!snapshot.hasData ||
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.data!.docs.isEmpty)
                          return const Center(
                            child: Text("No table details available."),
                          );

                        return ListView(
                          scrollDirection: Axis.horizontal,
                          children: snapshot.data!.docs.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            String docId = doc.id;

                            String tableName = data["tableName"] ?? "Unnamed";
                            String url = data["url"] ?? "";
                            String status = data["status"] ?? "Unknown";
                            String seats = data["seats"] ?? "N/A";
                            String time = data["time"] ?? "N/A";
                            var createdAt = data["createdAt"];
                            String date = createdAt != null
                                ? (createdAt as Timestamp)
                                      .toDate()
                                      .toString()
                                      .split(" ")
                                      .first
                                : "No Date";

                            return glassyCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url,
                                      height: 80,
                                      width: 140,
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
                                  Text(
                                    tableName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "Seats: $seats",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    "Status: $status",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: status == "booked"
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                  Text(
                                    "⏰ $time",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    "📅 $date",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: () => editTable(docId, data),
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => deleteTable(docId),
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
