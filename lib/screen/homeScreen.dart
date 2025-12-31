// home.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';

import 'foodDetail.dart';
import 'food_screen.dart';
import 'hotels_screen.dart';
import 'orders_screen.dart';
import 'package:food_app_imakes/screen/offerFood_detailPage.dart';
import 'package:food_app_imakes/screen/tableBooking.dart';

class Home extends StatefulWidget {
  final double? latitude;
  final double? longitude;

  const Home({super.key, this.latitude, this.longitude});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  String _userName = "User";
  String _userEmail = "user@email.com";

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    if (widget.latitude == null || widget.longitude == null) {
      _getCurrentLocation();
    } else {
      _latitude = widget.latitude;
      _longitude = widget.longitude;
    }
  }

  void _fetchUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? "User";
        _userEmail = user.email ?? "user@email.com";
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location service is disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        print("Permission denied forever");
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Finally get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      print("LOCATION ERROR: $e");

      // its use for web platform only
      if (e.toString().contains("Only secure origins are allowed")) {
        print("WEB ERROR: Location requires HTTPS to work.");
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget glassyCard({required Widget child, double width = 200}) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 238, 213, 213).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromARGB(255, 66, 61, 61).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeTab(
        latitude: _latitude,
        longitude: _longitude,
        glassyCard: glassyCard,
      ),
      const FoodScreen(),
      const HotelsScreen(),
      const OrdersScreen(),
    ];

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_userName),
              accountEmail: Text(_userEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Color.fromARGB(255, 112, 79, 79),
                child: Icon(Icons.person, size: 40, color: Colors.black),
              ),
              decoration: const BoxDecoration(color: Colors.deepOrangeAccent),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () => Navigator.pushNamed(context, "/profile"),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () => Navigator.pushNamed(context, "/settings"),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Top card only on home tab
          if (_selectedIndex == 0)
            Positioned(
              left: 0,
              right: 0,
              top: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: glassyCard(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 28,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  _userEmail,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.black,
                              size: 32,
                            ),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Main tab content below card (only Home has top offset)
          Positioned.fill(
            top: _selectedIndex == 0 ? 130 : 0,
            child: screens[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: "Food"),
          BottomNavigationBarItem(icon: Icon(Icons.hotel), label: "Hotels"),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: "Orders",
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

///  HOMETAB
class HomeTab extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final Widget Function({required Widget child, double width}) glassyCard;

  const HomeTab({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.glassyCard,
  });

  // distance in km
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0; // km
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    if (latitude == null || longitude == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Client-side filter: fetch all hotels, then keep those within 5 km and sort.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("hotels").snapshots(),
        builder: (context, hotelSnapshot) {
          if (hotelSnapshot.connectionState == ConnectionState.waiting) {
            return _shimmerHotelList();
          }
          if (hotelSnapshot.hasError) {
            return const Text("Error loading hotels");
          }
          if (!hotelSnapshot.hasData || hotelSnapshot.data!.docs.isEmpty) {
            return const Text("No hotels found.");
          }

          // Build list with distance
          final rawDocs = hotelSnapshot.data!.docs;
          final List<Map<String, dynamic>> nearby = [];

          for (var doc in rawDocs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) continue;

            // defensive fetch of coords
            final latVal = data['latitude'];
            final lonVal = data['longitude'];
            if (latVal == null || lonVal == null) continue;
            try {
              final double hotelLat = (latVal as num).toDouble();
              final double hotelLon = (lonVal as num).toDouble();

              final double dist = _calculateDistance(
                latitude!,
                longitude!,
                hotelLat,
                hotelLon,
              );

              if (dist <= 5.0) {
                // 5 km radius
                final Map<String, dynamic> entry = Map<String, dynamic>.from(
                  data,
                );
                entry['distance'] = dist;
                entry['id'] = doc.id;
                // normalize names: use hotelName if available, else name
                final dynamic hn = entry['hotelName'] ?? entry['name'];
                entry['displayName'] = (hn is String && hn.isNotEmpty)
                    ? hn
                    : 'Hotel';
                nearby.add(entry);
              }
            } catch (e) {
              // ignore documents with bad number types
              continue;
            }
          }

          if (nearby.isEmpty) {
            return const Text("No nearby hotels within 5 km.");
          }

          // sort by nearest
          nearby.sort(
            (a, b) =>
                (a['distance'] as double).compareTo(b['distance'] as double),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: nearby.map((hotel) {
              return _buildHotelCard(context, hotel);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildHotelCard(BuildContext context, Map<String, dynamic> hotel) {
    final String hotelId = hotel['id'] ?? '';
    final String hotelName = (hotel['displayName'] as String?) ?? 'Hotel';
    final double distance = (hotel['distance'] as double?) ?? 0.0;
    final String distanceLabel = "${distance.toStringAsFixed(2)} km away";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hotel header
        Row(
          children: [
            Expanded(
              child: Text(
                hotelName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(distanceLabel, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),

        // Food Items
        _sectionTitle("🍴 Food Items"),
        SizedBox(height: 200, child: _buildFoodSection(hotelId, context)),

        const SizedBox(height: 12),
        // Tables - only available ones
        _sectionTitle("🪑 Available Tables"),
        SizedBox(height: 140, child: _buildTableSection(hotelId, context)),

        const SizedBox(height: 12),
        // Offers - query by hotelName (because offers documents contain hotelName, not hotelId)
        _sectionTitle("🎉 Offers"),
        SizedBox(height: 180, child: _buildOfferSection(hotelName, context)),

        const Divider(thickness: 1),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildFoodSection(String hotelId, BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("menuItems")
          .where("hotelId", isEqualTo: hotelId)
          .snapshots(),
      builder: (context, foodSnapshot) {
        if (foodSnapshot.connectionState == ConnectionState.waiting) {
          return _shimmerHorizontal();
        }
        if (foodSnapshot.hasError) {
          return const Center(child: Text("Error loading food"));
        }
        if (!foodSnapshot.hasData || foodSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No food available"));
        }

        final foodDocs = foodSnapshot.data!.docs;

        return ListView(
          scrollDirection: Axis.horizontal,
          children: foodDocs.map((doc) {
            final food = doc.data() as Map<String, dynamic>? ?? {};
            final name = (food['name'] as String?) ?? 'Dish';
            final price = food['price']?.toString() ?? '--';
            final imageUrl = (food['imageUrl'] as String?) ?? '';

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodDetailPage(foodId: doc.id),
                  ),
                );
              },
              child: glassyCard(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            height: 100,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.fastfood,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 100,
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.fastfood,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹$price",
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTableSection(String hotelId, BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Only available tables
      stream: FirebaseFirestore.instance
          .collection("tables")
          .where("hotelId", isEqualTo: hotelId)
          .where("status", isEqualTo: "available")
          .snapshots(),
      builder: (context, tableSnapshot) {
        if (tableSnapshot.connectionState == ConnectionState.waiting) {
          return _shimmerHorizontal();
        }
        if (tableSnapshot.hasError) {
          return const Center(child: Text("Error loading tables"));
        }
        if (!tableSnapshot.hasData || tableSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No available tables"));
        }

        final tableDocs = tableSnapshot.data!.docs;

        return ListView(
          scrollDirection: Axis.horizontal,
          children: tableDocs.map((doc) {
            final table = doc.data() as Map<String, dynamic>? ?? {};
            final tableName = (table['tableName'] as String?) ?? '--';
            final seats = table['seats']?.toString() ?? '--';
            final url = (table['url'] as String?) ?? '';

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TableBookingPage(tableId: doc.id, tableData: table),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: SizedBox(
                  width: 160,
                  child: glassyCard(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[200],
                              image: (url.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(url),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (url.isEmpty)
                                ? const Icon(
                                    Icons.table_bar,
                                    size: 40,
                                    color: Colors.brown,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Table: $tableName",
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            "Seats: $seats",
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            "Status: available",
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOfferSection(String hotelName, BuildContext context) {
    // Query offers by hotelName because offers don't have hotelId in your schema.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("offers")
          .where("hotelName", isEqualTo: hotelName)
          .snapshots(),
      builder: (context, offerSnapshot) {
        if (offerSnapshot.connectionState == ConnectionState.waiting) {
          return _shimmerHorizontal();
        }
        if (offerSnapshot.hasError) {
          return const Center(child: Text("Error loading offers"));
        }
        if (!offerSnapshot.hasData || offerSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No offers available"));
        }

        final offers = offerSnapshot.data!.docs;

        return ListView(
          scrollDirection: Axis.horizontal,
          children: offers.map((doc) {
            final offer = doc.data() as Map<String, dynamic>? ?? {};
            final foodName = (offer['foodName'] as String?) ?? '--';
            final original = offer['originalRate']?.toString() ?? '--';
            final offerPrice = offer['offerPrice']?.toString() ?? '--';
            final imageUrl = (offer['imageUrl'] as String?) ?? '';
            final time = (offer['time'] as String?) ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: SizedBox(
                width: 200,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OfferDetailPage(offerId: doc.id, offerData: offer),
                      ),
                    );
                  },
                  child: glassyCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl.isNotEmpty)
                          Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 100,
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.local_offer,
                              size: 40,
                              color: Colors.deepOrange,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                foodName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "₹$original",
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text(
                                "₹$offerPrice",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              if (time.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  "Valid: $time",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Shimmer placeholders
  Widget _shimmerHorizontal() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(3, (index) {
          return Container(
            width: 180,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
      ),
    );
  }

  Widget _shimmerHotelList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
      ),
    );
  }
}
