import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:food_app_imakes/auth/authservice.dart';
import 'package:food_app_imakes/utils/messages.dart';

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = "user";
  bool loading = false;

  Future<void> signUp() async {
    setState(() => loading = true);

    String result = await AuthserviceHelper.createAccountWithEmail(
      emailController.text.trim(),
      passwordController.text.trim(),
      name: nameController.text.trim(),
      mobileNumber: mobileController.text.trim(),
      address: addressController.text.trim(),
      role: selectedRole,
    );

    setState(() => loading = false);

    if (result == "Account created successfully") {
      Message().showe(message: "Account Created");

      if (selectedRole == "hotelOwner") {
        Get.offAllNamed("/hotelOwnerHome");
      } else if (selectedRole == "admin") {
        Get.offAllNamed("/adminHome");
      } else if (selectedRole == "delivery") {
        Get.offAllNamed("/deliveryHome");
      } else {
        Get.offAllNamed("/home");
      }
    } else {
      Message().showe(message: "Error: $result");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 225, 41, 69), Color(0xFFfad0c4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🧊 Glassy Card
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Text(
                          'Create Account 🍜',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(nameController, "Name", Icons.person),
                        const SizedBox(height: 15),
                        _buildTextField(
                          mobileController,
                          "Mobile Number",
                          Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          addressController,
                          "Address",
                          Icons.home,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(emailController, "Email", Icons.email),
                        const SizedBox(height: 15),
                        _buildTextField(
                          passwordController,
                          "Password",
                          Icons.lock,
                          obscure: true,
                        ),
                        const SizedBox(height: 15),

                        // Role Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          dropdownColor: Colors.black87,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            labelStyle: const TextStyle(color: Colors.white),
                            label: const Text("Role"),
                          ),
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                              value: "user",
                              child: Text("User"),
                            ),
                            DropdownMenuItem(
                              value: "hotelOwner",
                              child: Text("Hotel Owner"),
                            ),
                            DropdownMenuItem(
                              value: "admin",
                              child: Text("Admin"),
                            ),
                            DropdownMenuItem(
                              value: "delivery",
                              child: Text("Delivery"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 25),

                        // SignUp Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: loading ? null : signUp,
                            child: loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Already have account?
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: () => Get.offAllNamed("/login"),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
