import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_app_imakes/screen/homeScreen.dart';

class PaymentPage extends StatefulWidget {
  final String offerId;
  final Map<String, dynamic> offerData;
  final int quantity;

  const PaymentPage({
    super.key,
    required this.offerId,
    required this.offerData,
    required this.quantity,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _upiController = TextEditingController();
  bool _paymentDone = false;
  String? _hotelName;
  String _selectedMethod = "Online";

  @override
  void initState() {
    super.initState();
    _fetchHotelName();
  }

  Future<void> _fetchHotelName() async {
    try {
      if (widget.offerData["hotelId"] != null) {
        final snap = await FirebaseFirestore.instance
            .collection("hotels")
            .doc(widget.offerData["hotelId"])
            .get();

        if (snap.exists) {
          setState(() {
            _hotelName = snap["hotelName"] ?? "Unknown Hotel";
          });
        }
      }
    } catch (e) {
      setState(() {
        _hotelName = "Unknown Hotel";
      });
    }
  }

  Future<void> completePayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final totalAmount =
        ((widget.offerData["offerPrice"] ?? widget.offerData["price"]) ?? 0) *
        widget.quantity;

    await FirebaseFirestore.instance.collection("orders").add({
      "userId": user.uid,
      "foodId": widget.offerId,
      "foodName": widget.offerData["foodName"] ?? widget.offerData["name"],
      "hotelId": widget.offerData["hotelId"], // keep hotelId
      "hotelName": _hotelName ?? "Unknown Hotel", // save fetched hotel name
      "imageUrl": widget.offerData["imageUrl"],
      "quantity": widget.quantity,
      "totalAmount": totalAmount,
      "upiId": _selectedMethod == "Online" ? _upiController.text : null,
      "paymentMethod": _selectedMethod,
      "status": "order placed",
      "orderAt": FieldValue.serverTimestamp(),
    });

    setState(() {
      _paymentDone = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Home()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_paymentDone) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, size: 120, color: Colors.green),
              SizedBox(height: 20),
              Text(
                "Order Placed Successfully!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    final totalAmount =
        ((widget.offerData["offerPrice"] ?? widget.offerData["price"]) ?? 0) *
        widget.quantity;

    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Payment method selection
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Online Payment"),
                    value: "Online",
                    groupValue: _selectedMethod,
                    onChanged: (val) {
                      setState(() {
                        _selectedMethod = val!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Cash on Delivery"),
                    value: "COD",
                    groupValue: _selectedMethod,
                    onChanged: (val) {
                      setState(() {
                        _selectedMethod = val!;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_selectedMethod == "Online") ...[
              TextField(
                controller: _upiController,
                decoration: const InputDecoration(
                  labelText: "Enter UPI ID",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Food: ${widget.offerData["foodName"] ?? widget.offerData["name"] ?? "Unknown"}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Hotel: ${_hotelName ?? "Loading..."}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Quantity: ${widget.quantity}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Total Amount: ₹$totalAmount",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 40,
                ),
              ),
              onPressed: completePayment,
              child: const Text("Buy", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
