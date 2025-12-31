import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_page.dart';

class OfferDetailPage extends StatefulWidget {
  final String offerId;
  final Map<String, dynamic> offerData;

  const OfferDetailPage({
    super.key,
    required this.offerId,
    required this.offerData,
  });

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  int quantity = 1;

  Future<void> addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection("cart").add({
      "userId": user.uid,
      "offerId": widget.offerId,
      "foodName": widget.offerData["foodName"],
      "imageUrl": widget.offerData["imageUrl"],
      "quantity": quantity,
      "offerPrice": widget.offerData["offerPrice"],
      "addedAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Item added to cart")));
  }

  @override
  Widget build(BuildContext context) {
    final price = (widget.offerData["offerPrice"] ?? 0) * quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Offer Details"),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child:
                  widget.offerData["imageUrl"] != null &&
                      widget.offerData["imageUrl"].toString().isNotEmpty
                  ? Image.network(
                      widget.offerData["imageUrl"],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.local_offer,
                        size: 60,
                        color: Colors.deepOrange,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // food name
            Text(
              widget.offerData["foodName"] ?? "Offer Food",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // prices
            Row(
              children: [
                Text(
                  "₹${widget.offerData["originalRate"] ?? "--"}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "₹${widget.offerData["offerPrice"] ?? "--"}",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // quantity selector
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (quantity > 1) setState(() => quantity--);
                  },
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                ),
                Text("$quantity", style: const TextStyle(fontSize: 18)),
                IconButton(
                  onPressed: () {
                    setState(() => quantity++);
                  },
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                ),
                const Spacer(),
                Text(
                  "Total: ₹$price",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Add to Cart",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            offerId: widget.offerId,
                            offerData: widget.offerData,
                            quantity: quantity,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Buy Now",
                      style: TextStyle(color: Colors.white),
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
