import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_app_imakes/screen/payment_page.dart';

class FoodDetailPage extends StatefulWidget {
  final String? foodId;
  final String? offerId;

  const FoodDetailPage({super.key, this.foodId, this.offerId})
    : assert(
        foodId != null || offerId != null,
        "Either foodId or offerId must be provided",
      );

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  Map<String, dynamic>? _foodData;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.foodId != null) {
      _fetchFoodData(widget.foodId!);
    } else if (widget.offerId != null) {
      _fetchOfferData(widget.offerId!);
    }
  }

  Future<void> _fetchFoodData(String foodId) async {
    final doc = await FirebaseFirestore.instance
        .collection("menuItems")
        .doc(foodId)
        .get();

    if (doc.exists) {
      setState(() {
        _foodData = doc.data();
      });
    }
  }

  Future<void> _fetchOfferData(String offerId) async {
    final doc = await FirebaseFirestore.instance
        .collection("offers")
        .doc(offerId)
        .get();

    if (doc.exists) {
      setState(() {
        _foodData = doc.data();
      });
    }
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _foodData == null) return;

    await FirebaseFirestore.instance.collection("cart").add({
      "userId": user.uid,
      "ownerId": _foodData!["ownerId"] ?? "",
      "foodId": widget.foodId ?? widget.offerId,
      "foodName": _foodData!["name"],
      "hotelName": _foodData!["hotelName"],
      "quantity": _quantity,
      "price": _foodData!["price"] ?? 0,
      "timestamp": FieldValue.serverTimestamp(),
      "isOffer": widget.offerId != null,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Added to cart ✅")));
  }

  void _buyNow() {
    if (_foodData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          offerId: widget.foodId ?? widget.offerId ?? "",
          offerData: _foodData!,
          quantity: _quantity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_foodData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(_foodData!["foodName"] ?? "Food Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl:
                  _foodData!["imageUrl"] ?? "https://via.placeholder.com/250",
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),

            Text(
              _foodData!["name"] ?? "Food Name",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "₹${_foodData!["price"] ?? "--"}",
              style: const TextStyle(fontSize: 20, color: Colors.green),
            ),
            const SizedBox(height: 10),

            if (_foodData!["hotelName"] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Restaurant: ${_foodData!["hotelName"]}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_foodData!["mobileNumber"] != null)
                    Text(
                      "Contact: ${_foodData!["mobileNumber"]}",
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),

            const SizedBox(height: 16),

            if (_foodData!["category"] != null)
              Text(
                "Category: ${_foodData!["category"]}",
                style: const TextStyle(fontSize: 16),
              ),

            if (_foodData!["description"] != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _foodData!["description"],
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Text("Quantity:", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _decreaseQuantity,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  _quantity.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  onPressed: _increaseQuantity,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _addToCart,
                    child: const Text(
                      "Add to Cart",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _buyNow,
                    child: const Text(
                      "Buy Now",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
